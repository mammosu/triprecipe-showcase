class CreateTagsAndRecipeTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :key, null: false
      t.string :label_ja
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :tags, :key, unique: true

    create_table :recipe_tags do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipe_tags, [ :recipe_id, :tag_id ], unique: true
  end
end
