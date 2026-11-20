class CreateRecipeReports < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_reports do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.text :comment
      t.string :status, null: false, default: "open"
      t.references :handled_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :recipe_reports, %i[recipe_id user_id], unique: true
  end
end
