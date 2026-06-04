class Chat < ApplicationRecord
  acts_as_chat

  # Polymorphic owner: a chat can belong to a User, Idea, Script, or
  # LinkedinPost (its "chattable"). optional: true preserves standalone chats
  # that have no owner — without it, acts_as_chat's own Chat.create! calls
  # would fail the implicit presence validation.
  belongs_to :chattable, polymorphic: true, optional: true
end
