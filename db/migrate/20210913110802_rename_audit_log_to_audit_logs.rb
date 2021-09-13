class RenameAuditLogToAuditLogs < ActiveRecord::Migration[6.1]
  def change
    rename_table :audit_log, :audit_logs
  end
end
