class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy
end
