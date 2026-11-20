class CreateRecipeShareTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_share_tokens do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :recipe_share_tokens, :token, unique: true
  end
end
