class Creator < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar
  validates :name, :topic, :goal, :audience, presence: true
  validate :avatar_must_be_an_image

  # The brand layer of the chat system prompt. `LlmContext` assembles each chat
  # node's #system_prompt into the full instruction; this is the topmost layer,
  # reached from a chat via `user.creator` (a Creator owns no chats itself).
  def system_prompt
    <<~TEXT.strip
      CREATOR PROFILE
      Name: #{name}
      Topic: #{topic}
      Goal: #{goal}
      Audience: #{audience}
    TEXT
  end

  private

  # Active Storage has no built-in validations, so we check the blob's
  # content type ourselves before a non-image (pdf, zip...) gets attached.
  def avatar_must_be_an_image
    errors.add(:avatar, "must be an image") if avatar.attached? && !avatar.image?
  end
end
