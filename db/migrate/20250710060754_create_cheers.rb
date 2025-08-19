class CreateCheers < ActiveRecord::Migration[7.2]
  def change
    create_table :cheers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :board, null: false, foreign_key: true

      t.timestamps
    end
  end
end
