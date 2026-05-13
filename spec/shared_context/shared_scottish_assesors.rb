shared_context "when testing Scottish assessors" do


  def add_assessors_to_logs
    audit_log = Gateway::AuditLogsGateway.new
    arr = ActiveRecord::Base.connection.exec_query("SELECT scheme_assessor_id FROM assessors").map { |row| row }

    arr.each do |i|
      audit_log.add_audit_event(Domain::AuditEvent.new(entity_type: :assessor, entity_id: i["scheme_assessor_id"], event_type: :added))
    end
  end

  # frozen_string_literal: true
end
