class Board < ApplicationRecord
  belongs_to :user
  belongs_to :goal

  validates :did_stretch, inclusion: { in: [true, false] }, presence: true
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :flexibility_level, numericality: { only_integer: true }, allow_nil: true
end
