class TwitterPost < ApplicationRecord
  belongs_to :script
  has_one :user, through: :script

  validates :script_id, uniqueness: true
  validates :title, presence: true
end
