class NotifyFactory
  ENTITY_TYPES = %w[assessment assessor].freeze
  EVENT_TYPE = ["opt in", "opt out", "lodgement"].freeze

  def self.lodgement_to_audit_log(entity_id, request)
    use_case = UseCase::SaveAuditEvent.new(Gateway::AuditLogsGateway.new)
    use_case.execute(Domain::AuditEvent.new(entity_type: ENTITY_TYPES[0], event_type: EVENT_TYPE[2], entity_id: entity_id, data: request.to_json))
  end
end
