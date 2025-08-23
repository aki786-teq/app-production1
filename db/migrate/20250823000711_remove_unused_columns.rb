class RemoveUnusedColumns < ActiveRecord::Migration[7.2]
  def change
    # 物理削除を使用するため、is_deletedカラムは不要
    remove_column :users, :is_deleted, :boolean if column_exists?(:users, :is_deleted)
    remove_column :boards, :is_deleted, :boolean if column_exists?(:boards, :is_deleted)

    # start_timeカラムは使用されていないため削除
    remove_column :boards, :start_time, :datetime if column_exists?(:boards, :start_time)
  end
end
