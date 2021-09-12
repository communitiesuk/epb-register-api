class ApiFactory
  def self.assessments_gateway
    @assessments_gateway ||= Gateway::AssessmentsGateway.new
  end

  def self.ni_assessments_gateway
    @ni_assessments_gateway ||= Gateway::ExportNiGateway.new
  end

  def self.reporting_gateway
    @reporting_gateway ||= Gateway::ReportingGateway.new
  end

  def self.assessments_search_gateway
    @assessments_search_gateway ||= Gateway::AssessmentsSearchGateway.new
  end

  def self.assessments_xml_gateway
    @assessments_xml_gateway ||= Gateway::AssessmentsXmlGateway.new
  end

  def self.assessors_gateway
    @assessors_gateway ||= Gateway::AssessorsGateway.new
  end

  def self.address_base_search_gateway
    @address_base_search_gateway ||= Gateway::AddressBaseSearchGateway.new
  end

  def self.assessments_address_id_gateway
    @assessments_address_id_gateway ||= Gateway::AssessmentsAddressIdGateway.new
  end

  def self.related_assessments_gateway
    @related_assessments_gateway ||= Gateway::RelatedAssessmentsGateway.new
  end

  def self.green_deal_plans_gateway
    @green_deal_plans_gateway ||= Gateway::GreenDealPlansGateway.new
  end

  def self.assessments_export_use_case
    @assessments_export_use_case ||=
      UseCase::ExportAssessmentAttributes.new(
        assessments_gateway,
        assessments_search_gateway,
        assessments_xml_gateway,
      )
  end

  def self.validate_and_lodge_assessment_use_case
    @validate_and_lodge_assessment_use_case ||=
      UseCase::ValidateAndLodgeAssessment.new(
        lodge_assessment_use_case: lodge_assessment_use_case,
        validate_assessment_use_case: validate_assessment_use_case,
        check_assessor_belongs_to_scheme_use_case: check_assessor_belongs_to_scheme_use_case,
      )
  end

  def self.check_assessor_belongs_to_scheme_use_case
    @check_assessor_belongs_to_scheme_use_case ||=
      UseCase::CheckAssessorBelongsToScheme.new(assessors_gateway: assessors_gateway)
  end

  def self.update_assessment_status_use_case
    @update_assessment_status_use_case ||= UseCase::UpdateAssessmentStatus.new(
      assessments_gateway: assessments_gateway,
      assessments_search_gateway: assessments_search_gateway,
      assessors_gateway: assessors_gateway,
      event_broadcaster: event_broadcaster,
    )
  end

  def self.opt_out_assessment_use_case
    @opt_out_assessment_use_case ||= UseCase::OptOutAssessment.new(
      assessments_gateway: assessments_gateway,
      assessments_search_gateway: assessments_search_gateway,
      event_broadcaster: event_broadcaster,
    )
  end

  def self.update_assessment_address_id_use_case
    @update_assessment_address_id_use_case ||= UseCase::UpdateAssessmentAddressId.new(
      address_base_gateway: address_base_search_gateway,
      assessments_address_id_gateway: assessments_address_id_gateway,
      assessments_search_gateway: assessments_search_gateway,
      assessments_gateway: assessments_gateway,
      event_broadcaster: event_broadcaster,
    )
  end

  def self.lodge_assessment_use_case
    @lodge_assessment_use_case ||=
      UseCase::LodgeAssessment.new(
        assessments_gateway: assessments_gateway,
        assessments_search_gateway: assessments_search_gateway,
        address_base_search_gateway: address_base_search_gateway,
        assessors_gateway: assessors_gateway,
        assessments_xml_gateway: assessments_xml_gateway,
        assessments_address_id_gateway: assessments_address_id_gateway,
        related_assessments_gateway: related_assessments_gateway,
        green_deal_plans_gateway: green_deal_plans_gateway,
        event_broadcaster: event_broadcaster,
      )
  end

  def self.validate_assessment_use_case
    @validate_assessment_use_case ||= UseCase::ValidateAssessment.new
  end

  def self.ni_assessments_export_use_case
    @ni_assessments_export_use_case ||= UseCase::ExportNiAssessments.new(export_ni_gateway: ni_assessments_gateway,
                                                                         xml_gateway: assessments_xml_gateway)
  end

  def self.export_not_for_publication_use_case
    @export_not_for_publication_use_case ||=
      UseCase::ExportOpenDataNotForPublication.new(reporting_gateway)
  end

  def self.notify_new_assessment_to_data_warehouse_use_case
    @notify_new_assessment_to_data_warehouse_use_case ||= UseCase::NotifyNewAssessmentToDataWarehouse.new(redis_gateway: redis_gateway)
  end

  def self.notify_assessment_status_update_to_data_warehouse_use_case
    @notify_assessment_status_update_to_data_warehouse_use_case ||= UseCase::NotifyAssessmentStatusUpdateToDataWarehouse.new(redis_gateway: redis_gateway)
  end

  def self.notify_assessment_address_id_update_to_data_warehouse_use_case
    @notify_assessment_address_id_update_to_data_warehouse_use_case ||= UseCase::NotifyAssessmentAddressIdUpdateToDataWarehouse.new(redis_gateway: redis_gateway)
  end

  def self.notify_opt_out_status_update_to_data_warehouse_use_case
    @notify_opt_out_status_update_to_data_warehouse_use_case ||= UseCase::NotifyOptOutStatusUpdateToDataWarehouse.new(redis_gateway: redis_gateway)
  end

  def self.storage_configuration_reader(bucket_name:, instance_name:)
    Gateway::StorageConfigurationReader.new(
      bucket_name: bucket_name,
      instance_name: instance_name,
    )
  end

  def self.storage_gateway(bucket_name:, instance_name:)
    Gateway::StorageGateway.new(
      storage_config:
        storage_configuration_reader(
          bucket_name: bucket_name,
          instance_name: instance_name,
        ).get_configuration,
    )
  end

  def self.redis_gateway
    @redis_gateway ||= Gateway::RedisGateway.new
  end

  def self.logger
    return @logger unless @logger.nil?

    @logger = Logger.new($stdout)
    @logger.level = Logger::ERROR

    @logger
  end

  def self.event_broadcaster
    return @event_broadcaster unless @event_broadcaster.nil?

    @event_broadcaster = EventBroadcaster.new

    # wire up listeners
    #
    # don't send out to data warehouse queue yet
    #
    @event_broadcaster.on :assessment_lodged do |assessment_id:|
      if notify_data_warehouse_enabled?
        notify_new_assessment_to_data_warehouse_use_case.execute(
          assessment_id: assessment_id,
        )
      end
    end

    @event_broadcaster.on :assessment_cancelled, :assessment_marked_not_for_issue do |assessment_id:|
      if notify_data_warehouse_enabled?
        notify_assessment_status_update_to_data_warehouse_use_case.execute(
          assessment_id: assessment_id,
        )
      end
    end

    @event_broadcaster.on :assessment_address_id_updated do |assessment_id:|
      if notify_data_warehouse_enabled?
        notify_assessment_address_id_update_to_data_warehouse_use_case.execute(
          assessment_id: assessment_id,
        )
      end
    end

    @event_broadcaster.on :assessment_opt_out_status_changed do |assessment_id:|
      if notify_data_warehouse_enabled?
        notify_opt_out_status_update_to_data_warehouse_use_case.execute(
          assessment_id: assessment_id,
        )
      end
    end

    @event_broadcaster
  end

private

  def self.notify_data_warehouse_enabled?
    Helper::Toggles.enabled? "sync_to_data_warehouse"
  end
end
