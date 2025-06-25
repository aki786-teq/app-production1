class CreateBoards < ActiveRecord::Migration[7.2]
  def change
    create_table :boards do |t|
      t.boolean :did_stretch, null: false
      t.text :content
      t.integer :flexibility_level
      t.references :user, null: false, foreign_key: true
      t.references :goal, null: false, foreign_key: true

      t.text :goal_title
      t.text :goal_content
      t.text :goal_reward
      t.text :goal_punishment

      t.timestamps
    end
  end
end
