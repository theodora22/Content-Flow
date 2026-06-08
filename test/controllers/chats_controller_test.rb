require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(email: "chat-create@cf.test", password: "password123")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    sign_in @user
  end

  test "create attaches the chattable and persists a creator-aware system message" do
    # The job only enqueues under the test adapter, so no LLM call fires —
    # the system instruction is persisted synchronously by with_instructions.
    assert_enqueued_with(job: ChatResponseJob) do
      post chats_path, params: {
        chat: {
          prompt: "Make this punchier",
          chattable_type: "Idea",
          chattable_id: @idea.id
        }
      }
    end

    chat = Chat.last
    assert_equal @idea, chat.chattable

    system_message = chat.messages.find_by(role: "system")
    assert system_message.present?, "expected a role: :system message"
    assert_includes system_message.content, "CREATOR PROFILE"
    assert_includes system_message.content, "PARENT IDEA"
    assert_includes system_message.content, "Ship faster"
  end

  test "create persists the user's prompt synchronously so it renders without the stream" do
    post chats_path, params: { chat: { prompt: "make it punchier" } }

    user_message = Chat.last.messages.find_by(role: "user")
    assert user_message.present?, "expected the prompt persisted as a user message before the job runs"
    assert_equal "make it punchier", user_message.content
  end

  test "create without a chattable leaves a standalone chat and no system message" do
    post chats_path, params: { chat: { prompt: "hello" } }

    chat = Chat.last
    assert_nil chat.chattable
    assert_nil chat.messages.find_by(role: "system")
  end

  test "create ignores a chattable_type outside the allowlist" do
    post chats_path, params: {
      chat: { prompt: "hi", chattable_type: "User", chattable_id: @user.id }
    }
    # User IS allowlisted; confirm a non-allowlisted type is rejected instead.
    post chats_path, params: {
      chat: { prompt: "hi", chattable_type: "Creator", chattable_id: @idea.id }
    }

    assert_nil Chat.last.chattable
  end

  test "create persists an allowlisted purpose" do
    post chats_path, params: { chat: { prompt: "hi", purpose: "generate_idea" } }

    assert_equal "generate_idea", Chat.last.purpose
  end

  test "create collapses an unknown purpose to nil (plain chat, unchanged)" do
    post chats_path, params: { chat: { prompt: "hi", purpose: "bogus" } }

    assert_nil Chat.last.purpose
  end

  test "new renders an allowlisted purpose into the form's hidden field" do
    get new_chat_path(purpose: "generate_idea")

    assert_response :success
    assert_select "input[type=hidden][name='chat[purpose]'][value=generate_idea]"
  end

  test "new seeds the chattable from the generate redirect's top-level params" do
    get new_chat_path(purpose: "generate_script", chattable_type: "Idea", chattable_id: @idea.id)

    assert_response :success
    assert_select "input[type=hidden][name='chat[chattable_type]'][value=Idea]"
    assert_select "input[type=hidden][name='chat[chattable_id]'][value=?]", @idea.id.to_s
  end

  test "create persists the chattable submitted via the form's hidden fields" do
    post chats_path, params: {
      chat: { prompt: "hi", purpose: "generate_script",
              chattable_type: "Idea", chattable_id: @idea.id }
    }

    assert_equal @idea, Chat.last.chattable
  end

  test "new ignores an unknown purpose (hidden field stays empty)" do
    get new_chat_path(purpose: "bogus")

    assert_response :success
    assert_select "input[type=hidden][name='chat[purpose]'][value=bogus]", count: 0
  end

  # ── show: purpose-aware headline ──────────────────────────────────────────

  test "show renders GENERATE AN IDEA headline for generate_idea" do
    chat = @user.chats.create!(purpose: "generate_idea")
    get chat_path(chat)
    assert_response :success
    assert_match "AN IDEA", response.body
  end

  test "show renders GENERATE A SCRIPT headline for generate_script" do
    chat = @user.chats.create!(purpose: "generate_script")
    get chat_path(chat)
    assert_match "A SCRIPT", response.body
  end

  test "show renders GENERATE A POST headline for generate_linkedin_post" do
    chat = @user.chats.create!(purpose: "generate_linkedin_post")
    get chat_path(chat)
    assert_match "A POST", response.body
  end

  test "show renders CHAT headline for a free-form chat" do
    chat = @user.chats.create!
    get chat_path(chat)
    assert_match ">CHAT<", response.body
  end

  # ── show: save-as button visibility gate ─────────────────────────────────

  test "show does not render the save button for a free-form chat even with an assistant reply" do
    chat = @user.chats.create!
    chat.messages.create!(role: "assistant", content: "here you go")
    get chat_path(chat)
    assert_select "form[action=?]", chat_generation_path(chat), count: 0
  end

  test "show does not render the save button when purpose is set but chattable is missing" do
    chat = Chat.create!(purpose: "generate_script")
    chat.messages.create!(role: "assistant", content: "here is a script")
    get chat_path(chat)
    assert_select "form[action=?]", chat_generation_path(chat), count: 0
  end

  test "show does not render the save button before any assistant reply" do
    chat = @user.chats.create!(purpose: "generate_idea")
    chat.messages.create!(role: "user", content: "give me an idea")
    get chat_path(chat)
    assert_select "form[action=?]", chat_generation_path(chat), count: 0
  end

  test "show renders the save button once an assistant reply exists" do
    chat = @user.chats.create!(purpose: "generate_idea")
    chat.messages.create!(role: "user", content: "give me an idea")
    chat.messages.create!(role: "assistant", content: "here is one")
    get chat_path(chat)
    assert_select "form[action=?]", chat_generation_path(chat)
    assert_select "button", "save as idea"
  end

  test "show renders save as script label for generate_script" do
    chat = @user.chats.create!(purpose: "generate_script")
    chat.messages.create!(role: "assistant", content: "here is a script")
    get chat_path(chat)
    assert_select "button", "save as script"
  end

  test "show renders save as linkedin post label for generate_linkedin_post" do
    chat = @user.chats.create!(purpose: "generate_linkedin_post")
    chat.messages.create!(role: "assistant", content: "here is a post")
    get chat_path(chat)
    assert_select "button", "save as linkedin post"
  end
end
