class CreateSavedRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end

    add_index :saved_recipes, %i[user_id recipe_id], unique: true
    add_index :saved_recipes, :recipe_id
  end
end
