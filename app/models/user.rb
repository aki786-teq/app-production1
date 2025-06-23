class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy
end
