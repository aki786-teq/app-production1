class RemoveUnusedColumns < ActiveRecord::Migration[7.2]
  def change
    # 物理削除を使用するため、is_deletedカラムは不要
    remove_column :users, :is_deleted, :boolean
    remove_column :boards, :is_deleted, :boolean

    # start_timeカラムは使用されていないため削除
    remove_column :boards, :start_time, :datetime
  end
end
