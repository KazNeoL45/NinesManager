class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.date :due_date
      t.references :project, null: false, foreign_key: true
      t.references :column, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :position
      t.boolean :recurring
      t.string :recurrence_pattern

      t.timestamps
    end
  end
end
