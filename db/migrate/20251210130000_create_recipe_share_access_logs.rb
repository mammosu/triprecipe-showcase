class CreateRecipeShareAccessLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_share_access_logs do |t|
      t.references :recipe_share_token, null: false, foreign_key: true
      t.datetime :accessed_at, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :recipe_share_access_logs, :accessed_at
  end
end
