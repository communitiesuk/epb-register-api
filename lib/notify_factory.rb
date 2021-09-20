require_relative "./controller/base_controller"

class NotifyFactory
  include RequestModule

  def self.lodgement_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :lodgement,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.opt_out_to_audit_log(entity_id:, is_opt_out:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: is_opt_out ? :opt_out : :opt_in,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.cancelled_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :cancelled,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.address_id_updated_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :address_id_updated,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.green_deal_plan_added_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :green_deal_plan_added,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.green_deal_plan_updated_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :green_deal_plan_updated,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.green_deal_plan_deleted_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :green_deal_plan_deleted,
                                        entity_id: entity_id,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.save_audit_event_use_case
    @save_audit_event_use_case ||= UseCase::SaveAuditEvent.new(Gateway::AuditLogsGateway.new)
  end

  private_class_method :save_audit_event_use_case
end
