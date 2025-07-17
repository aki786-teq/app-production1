class AddIntroduceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :introduce, :text, limit: 500
  end
end
