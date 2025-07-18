class AddConfirmableToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # メールアドレス変更用

    add_index :users, :confirmation_token, unique: true
  end
end
