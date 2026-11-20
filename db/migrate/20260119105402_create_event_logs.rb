class CreateEventLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :event_logs do |t|
      t.string :event_type, null: false
      t.references :recipe, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.json :metadata

      t.timestamps
    end
    add_index :event_logs, :event_type
  end
end
