class RemoveConsecutiveInactiveDaysFromLineNotifications < ActiveRecord::Migration[7.2]
  def change
    if column_exists?(:line_notifications, :consecutive_inactive_days)
      remove_column :line_notifications, :consecutive_inactive_days, :integer, default: 0, null: false
    end
  end
end
