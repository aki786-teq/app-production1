class AddMissingIndexToOauthAccounts < ActiveRecord::Migration[7.2]
  def change
    # インデックスが既に存在するかチェックしてから追加
    unless index_exists?(:oauth_accounts, [:user_id, :provider], name: "index_oauth_accounts_on_user_id_and_provider")
      add_index :oauth_accounts, [:user_id, :provider], unique: true, name: "index_oauth_accounts_on_user_id_and_provider"
    end
  end
end
