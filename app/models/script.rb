class Script < ApplicationRecord
  belongs_to :idea
  has_one :user, through: :idea
  has_one :linkedin_post, dependent: :destroy
  has_one :twitter_post, dependent: :destroy
  has_one :instagram_post, dependent: :destroy
  has_many :chats, as: :chattable, dependent: :destroy

  validates :title, presence: true
end
