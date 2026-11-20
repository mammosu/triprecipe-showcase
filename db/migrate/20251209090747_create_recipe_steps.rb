class CreateRecipeSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_steps do |t|
      t.references :recipe_day, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :title, null: false
      t.string :category, null: false, default: "activity"
      t.time :starts_at, null: false
      t.time :ends_at
      t.text :notes

      t.timestamps
    end

    add_index :recipe_steps, :recipe_day_id
    add_check_constraint :recipe_steps,
                         "ends_at IS NULL OR ends_at >= starts_at",
                         name: "recipe_steps_chronological"
  end
end
