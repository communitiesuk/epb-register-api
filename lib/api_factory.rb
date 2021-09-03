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

  def self.lodge_assessment_use_case
    return @lodge_assessment_use_case unless @lodge_assessment_use_case.nil?

    @lodge_assessment_use_case =
      UseCase::LodgeAssessment.new(
        assessments_gateway: assessments_gateway,
        assessments_search_gateway: assessments_search_gateway,
        address_base_search_gateway: address_base_search_gateway,
        assessors_gateway: assessors_gateway,
        assessments_xml_gateway: assessments_xml_gateway,
        assessments_address_id_gateway: assessments_address_id_gateway,
        related_assessments_gateway: related_assessments_gateway,
        green_deal_plans_gateway: green_deal_plans_gateway,
      )
    @lodge_assessment_use_case.subscribe(
      Listener::NotifyNewAssessmentToDataWarehouse.new(
        notify_use_case: notify_new_assessment_to_data_warehouse_use_case,
      ),
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
end
