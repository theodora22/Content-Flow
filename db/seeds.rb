
Message.update_all(tool_call_id: nil)
ToolCall.destroy_all

Message.destroy_all
LinkedinPost.destroy_all
Chat.destroy_all
Script.destroy_all
GeneratedIdea.destroy_all
Idea.destroy_all
Creator.destroy_all
User.destroy_all

# User
user = User.create!(
  email: "demo@contentflow.com",
  password: "password123",
  password_confirmation: "password123"
)

# Creator profile
Creator.create!(
  user: user,
  name: "Theodora",
  topic: "AI & Productivity",
  audience: "Startup founders and knowledge workers",
  goal: "Build thought leadership and grow my audience"
)

# Ideas ------------------------------------------------------------------------
idea1 = Idea.create!(
  user: user,
  title: "How AI is changing the way we create content",
  topic: "AI & Content Creation",
  description: "An exploration of how AI tools are transforming content workflows for creators and marketers."
)

idea2 = Idea.create!(
  user: user,
  title: "Building a personal brand with LinkedIn",
  topic: "Personal Branding",
  description: "A guide to using LinkedIn strategically to establish authority in your niche."
)

# Generated ideas --------------------------------------------------------------
GeneratedIdea.create!(
  user: user,
  idea: idea1,
  title: "5 AI tools every content creator needs right now",
  topic: "AI Tools",
  description: "A listicle exploring the top AI tools transforming content creation workflows."
)

GeneratedIdea.create!(
  user: user,
  idea: idea1,
  title: "Why AI won't replace human creativity",
  topic: "AI & Creativity",
  description: "A thought piece arguing that AI amplifies rather than replaces human creative thinking."
)

GeneratedIdea.create!(
  user: user,
  idea: idea2,
  title: "The LinkedIn post that changed my career trajectory",
  topic: "LinkedIn Strategy",
  description: "A personal story about a pivotal LinkedIn post and the lessons it taught."
)

# Scripts ----------------------------------------------------------------------
script1 = Script.create!(
  idea: idea1,
  title: "AI Content Creation Revolution",
  style: "educational",
  length: "short",
  description: "A short educational script covering the top AI tools transforming content creation.",
  system_prompt: "You are a knowledgeable tech content creator. Write engaging, concise scripts."
)

script2 = Script.create!(
  idea: idea2,
  title: "LinkedIn Personal Branding Masterclass",
  style: "conversational",
  length: "medium",
  description: "A conversational walkthrough of building a compelling LinkedIn presence from scratch.",
  system_prompt: "You are a personal branding expert. Write approachable, actionable scripts."
)

# LinkedIn posts ---------------------------------------------------------------
LinkedinPost.create!(
  script: script1,
  title: "AI tools post",
  hook: "I spent 30 days testing every AI content tool on the market. Here's what actually works:",
  body: <<~BODY
    Most AI tools promise to 10x your content output.

    Only 3 actually delivered.

    Here's what I learned:

    1. ChatGPT for first drafts — fast, but needs heavy editing
    2. Midjourney for visuals — the quality is genuinely impressive
    3. Descript for video editing — cuts production time in half

    The secret? AI works best as a thinking partner, not a replacement.

    What AI tools are you using for content creation?
  BODY
)

LinkedinPost.create!(
  script: script2,
  title: "LinkedIn branding post",
  hook: "3 years ago I had 200 LinkedIn followers. Today I have 50k. Here's the exact strategy I used:",
  body: <<~BODY
    It wasn't magic. It was a system.

    Step 1: Pick ONE topic and own it
    Step 2: Post 3× a week for 90 days straight
    Step 3: Engage genuinely — comments matter more than posts

    The biggest mistake people make?

    They post, then disappear.

    LinkedIn rewards consistency over perfection.

    What's your biggest LinkedIn challenge right now?
  BODY
)

# Chats and messages -----------------------------------------------------------
# Note: the chats table has no user_id or script_id column in the current
# schema, so chats are created as standalone records.
chat = Chat.create!

Message.create!(
  chat: chat,
  role: "user",
  content: "Help me brainstorm content ideas for my AI and productivity newsletter."
)

Message.create!(
  chat: chat,
  role: "assistant",
  content: <<~BODY
    Happy to help! Here are five angles that perform well for AI and productivity newsletters:

    1. Tool teardowns — Pick one AI tool each week and show exactly how you use it in your workflow
    2. Myth-busting — Address common misconceptions about AI in your field
    3. Case studies — Real examples of people saving time or creating better work with AI
    4. Trend commentary — Your take on the latest AI news, in plain language
    5. How-to guides — Step-by-step walkthroughs for specific tasks

    Which of these resonates most with your audience?
  BODY
)
