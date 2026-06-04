class Idea < ApplicationRecord
  belongs_to :user
  has_many :scripts, dependent: :destroy
  validates :title, presence: true
end
