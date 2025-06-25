class Goal < ApplicationRecord
  belongs_to :user
  has_many :boards

  validates :goal, presence: true
  validates :content, presence: true
end
