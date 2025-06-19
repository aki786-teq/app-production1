class Goal < ApplicationRecord
  belongs_to :user

  validates :goal, presence: true
  validates :content, presence: true
end
