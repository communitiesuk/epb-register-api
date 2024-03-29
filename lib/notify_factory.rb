require_relative "./controller/base_controller"

class NotifyFactory
  include RequestModule

  def self.lodgement_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :lodgement,
                                        entity_id:,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.opt_out_to_audit_log(entity_id:, is_opt_out:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: is_opt_out ? :opt_out : :opt_in,
                                        entity_id:,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.cancelled_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :cancelled,
                                        entity_id:,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.address_id_updated_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessment,
                                        event_type: :address_id_updated,
                                        entity_id:,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.green_deal_plan_added_to_audit_log(entity_id:, assessment_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :green_deal_plan,
                                        event_type: :green_deal_plan_added,
                                        entity_id:,
                                        data: merge_hash_to_json(json: RequestModule.relevant_request_headers, hash: { assessment_id: }),
                                      ))
  end

  def self.green_deal_plan_updated_to_audit_log(entity_id:, assessment_ids:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :green_deal_plan,
                                        event_type: :green_deal_plan_updated,
                                        entity_id:,
                                        data: merge_hash_to_json(json: RequestModule.relevant_request_headers, hash: { assessment_ids: }),
                                      ))
  end

  def self.green_deal_plan_deleted_to_audit_log(entity_id:, assessment_ids:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :green_deal_plan,
                                        event_type: :green_deal_plan_deleted,
                                        entity_id:,
                                        data: merge_hash_to_json(json: RequestModule.relevant_request_headers, hash: { assessment_ids: }),
                                      ))
  end

  def self.assessor_added_to_audit_log(entity_id:)
    save_audit_event_use_case.execute(Domain::AuditEvent.new(
                                        entity_type: :assessor,
                                        event_type: :added,
                                        entity_id:,
                                        data: RequestModule.relevant_request_headers,
                                      ))
  end

  def self.new_assessment_to_data_warehouse_use_case
    @new_assessment_to_data_warehouse_use_case ||= UseCase::NotifyNewAssessmentToDataWarehouse.new(redis_gateway: ApiFactory.data_warehouse_queues_gateway)
  end

  def self.assessment_status_update_to_data_warehouse_use_case
    @assessment_status_update_to_data_warehouse_use_case ||= UseCase::NotifyAssessmentStatusUpdateToDataWarehouse.new(redis_gateway: ApiFactory.data_warehouse_queues_gateway)
  end

  def self.assessment_address_id_update_to_data_warehouse_use_case
    @assessment_address_id_update_to_data_warehouse_use_case ||= UseCase::NotifyAssessmentAddressIdUpdateToDataWarehouse.new(redis_gateway: ApiFactory.data_warehouse_queues_gateway)
  end

  def self.opt_out_status_update_to_data_warehouse_use_case
    @opt_out_status_update_to_data_warehouse_use_case ||= UseCase::NotifyOptOutStatusUpdateToDataWarehouse.new(redis_gateway: ApiFactory.data_warehouse_queues_gateway)
  end

  def self.save_audit_event_use_case
    @save_audit_event_use_case ||= UseCase::SaveAuditEvent.new(Gateway::AuditLogsGateway.new)
  end

  def self.merge_hash_to_json(hash:, json:)
    JSON.fast_generate(JSON.parse(json, symbolize_names: true).merge(hash))
  end

  private_class_method :save_audit_event_use_case, :merge_hash_to_json
end
