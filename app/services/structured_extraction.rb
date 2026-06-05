# StructuredExtraction pulls a structured Hash out of the LLM, given one of our
# RubyLLM::Schema classes. It is the *input* side of the generation/refine path
# and pairs with StructuredContent (the *output* side, which maps the Hash onto
# a record).
#
# Two extraction strategies, tried in order:
#
#   1. PRIMARY — `with_schema`. We attach the schema so the request carries
#      `response_format: { type: "json_schema", ... }`. When the endpoint honors
#      it, the gem JSON.parses the reply into `message.content` (a Hash) for us
#      (see ruby_llm chat.rb:172). The day-1 F-3 spike confirmed our configured
#      GitHub-Models/Azure `gpt-4o-mini` endpoint honors this reliably, so this
#      is the path F-2 builds on.
#
#   2. FALLBACK — prompt-instructed JSON. If the endpoint ever *ignores*
#      `response_format` (or a model swap regresses), the gem silently returns
#      the raw String instead of a Hash (it rescues JSON::ParserError and keeps
#      the string). We detect that, then retry schema-less: we instruct the model
#      to "respond with only a JSON object with keys …", strip any ```json
#      fences, and JSON.parse with a rescue.
#
# Usage (F-2 generation path / R-2 refine path):
#
#   payload = StructuredExtraction.extract(
#     schema:       IdeaSchema,
#     prompt:       transcript,          # the user/assistant transcript or a single ask
#     instructions: LlmContext.for(...), # optional system instructions (cascading context)
#   )
#   StructuredContent.assign(idea, IdeaSchema, payload)
#   idea.save
#
# `extract` always returns a Hash on success and raises ExtractionFailed if both
# strategies fail to produce parseable JSON — callers get a Hash or a clear
# error, never the gem's "maybe a Hash, maybe a String" ambiguity.
class StructuredExtraction
  # Raised when neither the schema response nor the prompt-JSON fallback yields a
  # parseable JSON object. We fail loud so a broken generation surfaces rather
  # than silently writing nothing.
  class ExtractionFailed < StandardError; end

  # Matches a fenced code block: ```json\n{...}\n```  or  ```\n{...}\n```
  # Captures the inner content. `m` flag so `.` spans newlines.
  FENCE = /\A\s*```(?:json)?\s*\n?(.*?)\n?\s*```\s*\z/m

  def self.extract(schema:, prompt:, instructions: nil, model: RubyLLM.config.default_model)
    new(schema:, prompt:, instructions:, model:).extract
  end

  def initialize(schema:, prompt:, instructions: nil, model: RubyLLM.config.default_model)
    @schema = schema
    @prompt = prompt
    @instructions = instructions
    @model = model
  end

  def extract
    via_schema || via_prompt_fallback ||
      raise(ExtractionFailed, "model returned no parseable JSON for #{@schema}")
  end

  # --- Pure helpers (no network) — unit-tested directly. ---

  # Builds the fallback directive: the existing instructions (if any) followed by
  # a hard "JSON only with these keys" instruction. The schema's declared
  # property names are the requested keys, so the directive stays in sync with
  # the schema automatically.
  def self.json_directive(schema, instructions = nil)
    keys = schema.properties.keys.join(", ")
    directive = "Respond with ONLY a single JSON object with exactly these keys: #{keys}. " \
                "Do not wrap it in markdown code fences and do not add any prose, " \
                "explanation, or text before or after the JSON object."
    [instructions, directive].compact.join("\n\n")
  end

  # Turns a raw model string into a Hash, or nil if it can't. Strips code fences,
  # then JSON.parses; on ParserError returns nil so the caller can fail cleanly.
  # Accepts an already-parsed Hash too (harmless passthrough).
  def self.parse_json(raw)
    return raw if raw.is_a?(Hash)
    return nil unless raw.is_a?(String)

    JSON.parse(strip_fences(raw))
  rescue JSON::ParserError
    nil
  end

  # Removes a surrounding ```json … ``` (or ``` … ```) fence. If there is no
  # fence but the string has surrounding prose, narrows to the outermost
  # {…} object. Otherwise returns the trimmed string unchanged.
  def self.strip_fences(text)
    stripped = text.strip

    if (match = stripped.match(FENCE))
      return match[1].strip
    end

    open_brace = stripped.index("{")
    close_brace = stripped.rindex("}")
    return stripped[open_brace..close_brace] if open_brace && close_brace && close_brace > open_brace

    stripped
  end

  private

  # PRIMARY: attach the schema and let the gem parse. Only accept a Hash — a
  # String here means the endpoint ignored `response_format` and the gem fell
  # back to raw text, so we hand off to the prompt-JSON fallback.
  def via_schema
    content = base_chat.with_schema(@schema).ask(@prompt).content
    content if content.is_a?(Hash)
  rescue RubyLLM::Error
    nil
  end

  # FALLBACK: no schema. Merge the JSON directive into the system instructions in
  # a single `with_instructions` call (it defaults to replace, not append), then
  # parse the raw reply ourselves.
  def via_prompt_fallback
    raw = RubyLLM.chat(model: @model)
                 .with_instructions(self.class.json_directive(@schema, @instructions))
                 .ask(@prompt)
                 .content
    self.class.parse_json(raw)
  rescue RubyLLM::Error
    nil
  end

  # A fresh transient chat carrying the cascading LlmContext instructions, if any.
  def base_chat
    chat = RubyLLM.chat(model: @model)
    chat = chat.with_instructions(@instructions) if @instructions
    chat
  end
end
