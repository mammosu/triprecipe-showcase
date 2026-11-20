class AddCityReferenceToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_reference :recipes, :city, null: true, foreign_key: true
  end
end
