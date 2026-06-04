class Script < ApplicationRecord
  belongs_to :idea
  has_many :chats, as: :chattable, dependent: :destroy
end
