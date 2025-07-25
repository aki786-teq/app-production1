class CreateStretchDistances < ActiveRecord::Migration[7.2]
  def change
    create_table :stretch_distances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :board, null: true, foreign_key: true

      t.decimal :distance_cm, precision: 4, scale: 1, null: false
      t.decimal :height_cm, precision: 4, scale: 1, null: false

      t.text :comment_template
      t.string :flexibility_level

      t.timestamps
    end
    add_index :stretch_distances, [:user_id, :created_at]
  end
end
