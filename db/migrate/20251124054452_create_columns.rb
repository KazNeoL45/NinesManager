class CreateColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :columns do |t|
      t.string :name
      t.integer :position
      t.references :board, null: false, foreign_key: true

      t.timestamps
    end
  end
end
