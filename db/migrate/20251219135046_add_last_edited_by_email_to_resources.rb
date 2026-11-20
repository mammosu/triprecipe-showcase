class AddLastEditedByEmailToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :last_edited_by_email, :string
    add_column :recipe_days, :last_edited_by_email, :string
    add_column :recipe_steps, :last_edited_by_email, :string
  end
end
