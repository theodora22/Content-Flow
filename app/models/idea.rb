class Idea < ApplicationRecord
  belongs_to :user
  has_many :chats, as: :chattable, dependent: :destroy
end
