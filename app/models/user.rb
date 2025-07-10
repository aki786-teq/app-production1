class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy

  # 削除前に関連データを適切な順序で削除
  before_destroy :cleanup_dependencies

  private

  def cleanup_dependencies
    boards.destroy_all
    goal&.destroy
  end
end
