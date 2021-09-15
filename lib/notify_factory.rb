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

  def self.opt_out_to_audit_log(entity_id:, is_opt_out:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: ENTITY_TYPES[0],
                                        event_type: is_opt_out ? "opt out" : "opt in",
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.save_audit_event_use_case
    @save_audit_event_use_case ||= UseCase::SaveAuditEvent.new(Gateway::AuditLogsGateway.new)
  end

  private_class_method :save_audit_event_use_case
end
