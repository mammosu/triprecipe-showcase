class AddForkedFromRecipeToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_reference :recipes, :forked_from_recipe, foreign_key: { to_table: :recipes, on_delete: :nullify }, index: true
  end
end
