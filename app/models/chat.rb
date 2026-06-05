class Chat < ApplicationRecord
  acts_as_chat

  # Polymorphic owner: a chat can belong to a User, Idea, Script, or
  # LinkedinPost (its "chattable"). optional: true preserves standalone chats
  # that have no owner — without it, acts_as_chat's own Chat.create! calls
  # would fail the implicit presence validation.
  belongs_to :chattable, polymorphic: true, optional: true

  # What this chat is for. Declaring an enum over the string `purpose` column
  # gives us, for each key:
  #   - a scope          Chat.generate_idea            (WHERE purpose = 'generate_idea')
  #   - a predicate      chat.generate_idea?           (=> true/false)
  #   - a bang setter    chat.generate_idea!           (sets + saves the value)
  # plus a `Chat.purposes` hash of the allowed values. Because the column is a
  # string, each key maps to its own string (rather than enum's default integer
  # indexing) — so the DB stores "generate_idea", not 0.
  #
  # `validate: { allow_nil: true }` adds an inclusion validation: an unknown
  # value becomes a validation error (record invalid) instead of raising
  # ArgumentError on assignment, and nil stays valid — a NULL purpose is a plain
  # free-form chat, so acts_as_chat's own Chat.create! and the existing /chats
  # flow are untouched.
  enum :purpose, {
    generate_idea: "generate_idea",
    generate_script: "generate_script",
    generate_linkedin_post: "generate_linkedin_post"
  }, validate: { allow_nil: true }
end
