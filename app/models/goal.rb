class Goal < ApplicationRecord
  belongs_to :user
  has_many :boards, dependent: :destroy

  validates :goal, presence: true
  validates :content, presence: true
end
