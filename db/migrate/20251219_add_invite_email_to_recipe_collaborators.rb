class AddInviteEmailToRecipeCollaborators < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_collaborators, :invite_email, :string

    # Allow collaborator rows to reference no user (invitation to an email)
    change_column_null :recipe_collaborators, :user_id, true

    # Prevent duplicate invites by email scoped to recipe
    add_index :recipe_collaborators, [ :recipe_id, :invite_email ], unique: true, name: "index_recipe_collaborators_on_recipe_id_and_invite_email", where: "invite_email IS NOT NULL"
  end
end
