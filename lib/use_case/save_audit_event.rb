module UseCase
  class SaveAuditEvent
    def initialize(audit_log_gateway)
      @audit_log_gateway = audit_log_gateway
    end

    def execute(audit_event_object)
      raise Boundary::ArgumentMissing unless audit_event_object.is_a?(Domain::AuditEvent)

      @audit_log_gateway.add_audit_event(audit_event_object)
    end
  end
end
