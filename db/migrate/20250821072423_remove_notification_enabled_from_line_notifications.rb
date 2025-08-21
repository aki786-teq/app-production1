class RemoveNotificationEnabledFromLineNotifications < ActiveRecord::Migration[7.2]
  def change
    remove_column :line_notifications, :notification_enabled, :boolean
  end
end
