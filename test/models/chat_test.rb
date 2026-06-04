require "test_helper"

class ChatTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "chat-owner@cf.test", password: "password123")
  end

  test "a chat can belong to a polymorphic chattable owner" do
    chat = @user.chats.create!

    assert_equal @user, chat.chattable
    assert_equal "User", chat.chattable_type
    assert_equal @user.id, chat.chattable_id
    assert_includes @user.chats, chat
  end

  test "a chat is valid with no owner (optional polymorphic association)" do
    chat = Chat.new

    assert chat.valid?, "standalone chats must remain valid for the existing /chats flow"
    assert_nil chat.chattable
  end

  test "ideas, scripts, and linkedin posts each own chats via chattable" do
    idea   = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    script = Script.create!(idea: idea, title: "s", style: "educational",
                            length: "short", description: "d", system_prompt: "p")
    post   = LinkedinPost.create!(script: script, title: "p", hook: "h", body: "b")

    [ idea, script, post ].each do |owner|
      chat = owner.chats.create!
      assert_equal owner, chat.chattable
      assert_includes owner.chats, chat
    end
  end

  test "destroying an owner destroys its chats" do
    idea = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    idea.chats.create!

    assert_difference -> { Chat.count }, -1 do
      idea.destroy
    end
  end
end
