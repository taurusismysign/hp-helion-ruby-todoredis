class CreateTodos < ActiveRecord::Migration
  def change
    create_table :todos do |t|
      t.string :description
      t.boolean :is_completed
      t.datetime :target_date

      t.timestamps null: false
    end
  end
end
