class CreateRecipeDays < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_days do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :day_order, null: false
      t.string :title, null: false
      t.text :notes
      t.date :starts_on

      t.timestamps
    end

    add_index :recipe_days, %i[recipe_id day_order], unique: true
    add_index :recipe_days, :recipe_id
    add_check_constraint :recipe_days,
                         "day_order >= 1",
                         name: "recipe_days_day_order_positive"
  end
end
