class AddPhotosStateToRecipeSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_steps, :photos_state, :text
  end
end
