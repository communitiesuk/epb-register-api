require_relative "./controller/base_controller"

class NotifyFactory
  include RequestModule

  ENTITY_TYPES = %w[assessment assessor].freeze

  def self.lodgement_to_audit_log(entity_id:)
    use_case = UseCase::SaveAuditEvent.new(Gateway::AuditLogsGateway.new)
    use_case.execute(Domain::AuditEvent.new(
                       entity_type: ENTITY_TYPES[0],
                       event_type: "lodgement",
                       entity_id: entity_id,
                       data: RequestModule.relevant_request_headers,
                     ))
  end
end
