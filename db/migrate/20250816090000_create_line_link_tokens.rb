class CreateLineLinkTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :line_link_tokens do |t|
      t.string :token, null: false, comment: "連携URLで使用する一意トークン"
      t.string :messaging_user_id, null: false, comment: "LINE Messaging APIのユーザーID"
      t.references :user, foreign_key: true
      t.datetime :expires_at, null: false, comment: "トークンの有効期限"
      t.datetime :consumed_at, comment: "トークンを使用した日時"
      t.timestamps
    end

    add_index :line_link_tokens, :token, unique: true
    add_index :line_link_tokens, :messaging_user_id
  end
end
