class AddLineIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :line_id, :string
    add_index :users, :line_id
  end
end
