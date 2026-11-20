class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.string :city
      t.integer :days_count
      t.text :description
      t.boolean :public, null: false, default: true
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipes, :slug, unique: true
    add_check_constraint :recipes,
                         "days_count IS NULL OR (days_count >= 1 AND days_count <= 60)",
                         name: "recipes_days_count_range"
  end
end
