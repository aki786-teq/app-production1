class LineNotification < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :notification_enabled, inclusion: { in: [ true, false ] }
  validates :consecutive_inactive_days, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_defaults, if: :new_record?

  # 通知が有効なユーザーのみを取得
  scope :notification_enabled, -> { where(notification_enabled: true) }

  # 通知記録を更新
  def record_notification!
    update!(
      last_notified_at: Time.current,
      consecutive_inactive_days: consecutive_inactive_days + 1
    )
  end

  # 投稿があった際の無投稿日数リセット
  def reset_inactive_days!
    update!(consecutive_inactive_days: 0)
  end

  # 通知可能かチェック（同日の重複通知防止）
  def can_notify_today?
    return true if last_notified_at.nil?
    last_notified_at.to_date != Date.current
  end

  private

  def set_defaults
    self.notification_enabled = true if notification_enabled.nil?
  end
end
