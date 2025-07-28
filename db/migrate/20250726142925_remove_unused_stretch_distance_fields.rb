class RemoveUnusedStretchDistanceFields < ActiveRecord::Migration[7.2]
  def change
    remove_column :stretch_distances, :distance_cm, :decimal
    remove_column :stretch_distances, :height_cm, :decimal
  end
end
