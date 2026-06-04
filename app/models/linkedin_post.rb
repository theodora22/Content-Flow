class LinkedinPost < ApplicationRecord
  belongs_to :script
  has_many :chats, as: :chattable, dependent: :destroy
end
