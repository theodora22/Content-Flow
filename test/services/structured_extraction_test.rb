require "test_helper"

# Unit tests for StructuredExtraction. The pure helpers (strip_fences,
# parse_json, json_directive) are exercised directly with no network. The
# primary/fallback selection in #extract is tested with anonymous subclasses
# that override the two strategy methods, so the suite never makes a real LLM
# call (the live endpoint is verified by the F-3 spike, not in CI).
class StructuredExtractionTest < ActiveSupport::TestCase
  # --- strip_fences ---

  test "strip_fences removes a ```json fence" do
    raw = "```json\n{\"title\":\"Hi\"}\n```"
    assert_equal '{"title":"Hi"}', StructuredExtraction.strip_fences(raw)
  end

  test "strip_fences removes a bare ``` fence" do
    raw = "```\n{\"title\":\"Hi\"}\n```"
    assert_equal '{"title":"Hi"}', StructuredExtraction.strip_fences(raw)
  end

  test "strip_fences narrows to the JSON object when prose surrounds it" do
    raw = "Sure! Here is your object:\n{\"title\":\"Hi\"}\nHope that helps."
    assert_equal '{"title":"Hi"}', StructuredExtraction.strip_fences(raw)
  end

  test "strip_fences leaves a clean JSON string untouched" do
    raw = '{"title":"Hi"}'
    assert_equal '{"title":"Hi"}', StructuredExtraction.strip_fences(raw)
  end

  # --- parse_json ---

  test "parse_json parses a fenced JSON string into a Hash" do
    raw = "```json\n{\"title\":\"Ship faster\",\"topic\":\"AI\"}\n```"
    assert_equal({ "title" => "Ship faster", "topic" => "AI" }, StructuredExtraction.parse_json(raw))
  end

  test "parse_json returns nil on unparseable text" do
    assert_nil StructuredExtraction.parse_json("not json at all")
  end

  test "parse_json passes a Hash through unchanged" do
    hash = { "title" => "Hi" }
    assert_same hash, StructuredExtraction.parse_json(hash)
  end

  test "parse_json returns nil for non-string, non-hash input" do
    assert_nil StructuredExtraction.parse_json(42)
  end

  # --- json_directive ---

  test "json_directive lists the schema keys and demands JSON-only output" do
    directive = StructuredExtraction.json_directive(IdeaSchema)
    assert_includes directive, "title, description, topic"
    assert_includes directive, "ONLY"
  end

  test "json_directive prepends existing instructions" do
    directive = StructuredExtraction.json_directive(IdeaSchema, "You are a strategist.")
    assert directive.start_with?("You are a strategist."), "context should come first"
    assert_includes directive, "title, description, topic"
  end

  # --- extract: primary/fallback selection (no network) ---
  #
  # Minitest 6 dropped Object#stub, so we override the two strategy methods with
  # tiny anonymous subclasses instead of mocking the LLM call.

  def extraction(via_schema:, via_fallback:)
    Class.new(StructuredExtraction) do
      define_method(:via_schema) { via_schema.respond_to?(:call) ? via_schema.call : via_schema }
      define_method(:via_prompt_fallback) { via_fallback.respond_to?(:call) ? via_fallback.call : via_fallback }
    end.new(schema: IdeaSchema, prompt: "x")
  end

  test "extract returns the schema Hash when the primary path succeeds" do
    hash = { "title" => "From schema" }
    # The fallback raises if consulted, proving the primary short-circuits.
    subject = extraction(via_schema: hash, via_fallback: -> { flunk "fallback should not run" })

    assert_equal hash, subject.extract
  end

  test "extract falls back to prompt-JSON when the primary returns no Hash" do
    fallback_hash = { "title" => "From fallback" }
    subject = extraction(via_schema: nil, via_fallback: fallback_hash)

    assert_equal fallback_hash, subject.extract
  end

  test "extract raises ExtractionFailed when both strategies fail" do
    subject = extraction(via_schema: nil, via_fallback: nil)

    assert_raises(StructuredExtraction::ExtractionFailed) { subject.extract }
  end
end
