class AddUniqueIndexToCheers < ActiveRecord::Migration[7.2]
  def change
    add_index :cheers, [ :user_id, :board_id ], unique: true
  end
end
