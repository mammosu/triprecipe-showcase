class CreateRecipeSlugs < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_slugs do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :slug, null: false

      t.timestamps
    end

    add_index :recipe_slugs, :slug, unique: true
  end
end
