class ApiFactory
  def self.assessments_gateway
    @assessments_gateway ||= Gateway::AssessmentsGateway.new
  end

  def self.assessments_search_gateway
    @assessments_search_gateway ||= Gateway::AssessmentsSearchGateway.new
  end

  def self.assessments_xml_gateway
    @assessments_xml_gateway ||= Gateway::AssessmentsXmlGateway.new
  end

  def self.assessments_export_use_case
    @assessments_export_use_case ||=
      UseCase::ExportAssessmentAttributes.new(
        assessments_gateway,
        assessments_search_gateway,
        assessments_xml_gateway,
      )
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
end
