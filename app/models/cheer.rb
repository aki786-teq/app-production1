class Cheer < ApplicationRecord
  belongs_to :user
  belongs_to :board

  has_one :notification, as: :subject, dependent: :destroy

  validates :user_id, uniqueness: { scope: :board_id }

  after_create_commit :create_notifications

  private
  def create_notifications
    Notification.create(subject: self, user: board.user, action_type: :cheer)
  end
end
