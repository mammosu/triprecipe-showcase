class AddLastEditedByToRecipesAndChildren < ActiveRecord::Migration[8.1]
  def change
    add_reference :recipes, :last_edited_by, foreign_key: { to_table: :users }, null: true
    add_reference :recipe_days, :last_edited_by, foreign_key: { to_table: :users }, null: true
    add_reference :recipe_steps, :last_edited_by, foreign_key: { to_table: :users }, null: true
  end
end
