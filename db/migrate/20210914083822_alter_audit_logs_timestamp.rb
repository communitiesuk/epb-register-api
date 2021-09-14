class AlterAuditLogsTimestamp < ActiveRecord::Migration[6.1]
  def change
    execute "alter table audit_logs alter column timestamp set default now()"
  end
end
