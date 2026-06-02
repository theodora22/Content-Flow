class Creator < ApplicationRecord
  belongs_to :user
  validates :name, :topic, :goal, :audience, pressence: true
end
