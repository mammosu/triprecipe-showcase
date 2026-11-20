class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string  :item_type, null: false
      t.bigint  :item_id,   null: false
      t.string  :action,    null: false
      t.bigint  :whodunnit
      t.json    :metadata,  null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [ :item_type, :item_id ]
    add_index :audit_logs, :whodunnit
    add_index :audit_logs, :created_at
  end
end
