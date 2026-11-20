class AddActorEmailToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :actor_email, :string
    add_index :versions, :actor_email
  end
end
