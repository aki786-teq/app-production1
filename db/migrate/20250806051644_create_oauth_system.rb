class CreateOauthSystem < ActiveRecord::Migration[7.2]
  def up
    # 1. LINE通知テーブルを作成
    create_table :line_notifications do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_notified_at
      t.boolean :notification_enabled, default: true, null: false
      t.integer :consecutive_inactive_days, default: 0, null: false
      t.timestamps
    end

    add_index :line_notifications, :last_notified_at

    # 2. OAuthAccountテーブルを作成
    create_table :oauth_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.json :auth_data
      t.timestamps
    end

    add_index :oauth_accounts, [ :provider, :uid ], unique: true

    # 3. 既存のSNS連携データをOAuthAccountテーブルに移行
    migrate_existing_oauth_data

    # 4. 古いOAuthカラムを削除
    remove_old_oauth_columns
  end

  def down
    # 1. テーブルを削除
    drop_table :oauth_accounts if table_exists?(:oauth_accounts)
    drop_table :line_notifications if table_exists?(:line_notifications)

    # 2. 古いOAuthカラムを復元
    restore_old_oauth_columns
  end

  private

  def migrate_existing_oauth_data
    User.where.not(provider: [ nil, '' ]).find_each do |user|
      next if user.oauth_accounts.exists?(provider: user.provider)

      user.oauth_accounts.create!(
        provider: user.provider,
        uid: user.uid,
        auth_data: nil
      )
    end
  end

  def remove_old_oauth_columns
    old_columns = [ :provider, :uid ]
    old_columns.each do |column|
      remove_column :users, column, :string if column_exists?(:users, column)
    end

    remove_index :users, [ :provider, :uid ], if_exists: true
  end

  def restore_old_oauth_columns
    old_columns = [ :provider, :uid ]
    old_columns.each do |column|
      add_column :users, column, :string unless column_exists?(:users, column)
    end

    add_index :users, [ :provider, :uid ], unique: true, name: "index_users_on_provider_and_uid" if column_exists?(:users, :provider) &&
                                          column_exists?(:users, :uid) &&
                                          !index_exists?(:users, [ :provider, :uid ])
  end
end
