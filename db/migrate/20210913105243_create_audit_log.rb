class CreateAuditLog < ActiveRecord::Migration[6.1]
  def change
    create_table :audit_log, primary_key: nil do |t|
      t.string :event_type, null: false
      t.datetime :timestamp, null: false, default: Time.now
      t.string :entity_id, null: false
      t.string  :entity_type, null: false
      t.jsonb  :data, null: true

      # add_index :audit_log, :entity_id
      # add_index :audit_log, :timestamp
      # add_index :audit_log, :event_type
    end
  end
end
