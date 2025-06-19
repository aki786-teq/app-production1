class CreateGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.text :goal
      t.text :content
      t.text :reward
      t.text :punishment

      t.timestamps
    end
  end
end
