class CreateLineNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :line_notifications do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_notified_at
      t.boolean :notification_enabled, default: true, null: false
      t.integer :consecutive_inactive_days, default: 0, null: false
      t.timestamps
    end

    add_index :line_notifications, :last_notified_at
  end
end
