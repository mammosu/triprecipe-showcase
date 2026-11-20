class CreateRecipeCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_collaborators do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "viewer"
      t.string :invitation_token
      t.datetime :invited_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :recipe_collaborators, [ :recipe_id, :user_id ], unique: true
    add_index :recipe_collaborators, :invitation_token, unique: true, where: "invitation_token IS NOT NULL"
  end
end
