class AddIndexesToAuditLogs < ActiveRecord::Migration[6.1]
  def change
    add_index :audit_logs, :timestamp
    add_index :audit_logs, :event_type
    add_index :audit_logs, :entity_id
  end
end
