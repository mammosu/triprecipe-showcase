class RenameRecipesCityToCityDisplay < ActiveRecord::Migration[8.1]
  def change
    rename_column :recipes, :city, :city_display
  end
end
