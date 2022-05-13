require_relative "./notify_factory"

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

  def self.schemes_gateway
    @schemes_gateway ||= Gateway::SchemesGateway.new
  end

  def self.assessors_status_events_gateway
    @assessors_status_events_gateway ||= Gateway::AssessorsStatusEventsGateway.new
  end

  def self.assessment_statistics_gateway
    @assessment_statistics_gateway ||= Gateway::AssessmentStatisticsGateway.new
  end

  def self.boiler_upgrade_scheme_gateway
    @boiler_upgrade_scheme_gateway ||= Gateway::BoilerUpgradeSchemeGateway.new
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
        check_approved_software_use_case: check_approved_software_use_case,
      )
  end

  def self.check_assessor_belongs_to_scheme_use_case
    @check_assessor_belongs_to_scheme_use_case ||=
      UseCase::CheckAssessorBelongsToScheme.new(assessors_gateway: assessors_gateway)
  end

  def self.check_approved_software_use_case
    @check_approved_software_use_case ||= UseCase::CheckApprovedSoftware.new logger: logger
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

  def self.save_daily_assessments_stats_use_case
    @save_daily_assessments_stats_use_case ||= UseCase::SaveDailyAssessmentsStats.new(
      assessment_statistics_gateway,
    )
  end

  def self.format_daily_stats_for_slack_use_case
    @format_daily_stats_for_slack_use_case ||= UseCase::FormatDailyStatsForSlack.new(
      assessment_statistics_gateway,
    )
  end

  def self.add_green_deal_plan_use_case
    @add_green_deal_plan_use_case ||=
      UseCase::AddGreenDealPlan.new(
        assessments_search_gateway: assessments_search_gateway,
        green_deal_plans_gateway: green_deal_plans_gateway,
        event_broadcaster: event_broadcaster,
      )
  end

  def self.update_green_deal_plan_use_case
    @update_green_deal_plan_use_case ||=
      UseCase::UpdateGreenDealPlan.new(
        green_deal_plans_gateway: green_deal_plans_gateway,
        event_broadcaster: event_broadcaster,
      )
  end

  def self.delete_green_deal_plan_use_case
    @delete_green_deal_plan_use_case ||=
      UseCase::DeleteGreenDealPlan.new(
        green_deal_plans_gateway: green_deal_plans_gateway,
        event_broadcaster: event_broadcaster,
      )
  end

  def self.add_assessor_use_case
    @add_assessor_use_case ||=
      UseCase::AddAssessor.new(
        schemes_gateway: schemes_gateway,
        assessors_gateway: assessors_gateway,
        assessors_status_events_gateway: assessors_status_events_gateway,
        event_broadcaster: event_broadcaster,
      )
  end

  def self.fetch_assessment_for_bus_use_case
    @fetch_assessment_for_bus_use_case ||=
      UseCase::FetchAssessmentForBus.new(bus_gateway: boiler_upgrade_scheme_gateway)
  end

  def self.find_assessments_for_bus_by_address_use_case
    @find_assessments_for_bus_by_address_use_case ||=
      UseCase::FindAssessmentsForBusByAddress.new(bus_gateway: boiler_upgrade_scheme_gateway)
  end

  def self.find_assessments_for_bus_by_uprn_use_case
    @find_assessments_for_bus_by_uprn_use_case ||=
      UseCase::FindAssessmentsForBusByUprn.new(bus_gateway: boiler_upgrade_scheme_gateway)
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

    @event_broadcaster = Events::Broadcaster.new(logger: logger)
    Events::Listener.new(@event_broadcaster).attach_listeners

    @event_broadcaster
  end

  # Clears out all memoized service instances. Useful for tests.
  def self.clear!
    instance_variables.each { |variable| instance_variable_set variable, nil }
  end
end
