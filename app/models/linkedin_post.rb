class LinkedinPost < ApplicationRecord
  belongs_to :script
  has_many :chats, as: :chattable, dependent: :destroy

  validates :script_id, uniqueness: true
  validates :title, presence: true
end
