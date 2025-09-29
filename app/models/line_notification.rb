class LineNotification < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true

  # リマインド通知を送信したとき通知記録を更新
  def record_notification!
    update!(last_notified_at: Time.current)
  end

  # 通知可能かチェック（同日の重複通知防止）
  def can_notify_today?
    return true if last_notified_at.nil?
    last_notified_at.to_date != Date.current
  end
end
