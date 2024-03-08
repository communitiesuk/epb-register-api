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

  def self.address_base_country_gateway
    @address_base_country_gateway ||= Gateway::AddressBaseCountryGateway.new
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

  def self.retrofit_funding_scheme_gateway
    @retrofit_funding_scheme_gateway ||= Gateway::RetrofitFundingSchemeGateway.new
  end

  def self.domestic_digest_gateway
    @domestic_digest_gateway ||= Gateway::DomesticDigestGateway.new
  end

  def self.domestic_epc_search_gateway
    @domestic_epc_search_gateway ||= Gateway::DomesticEpcSearchGateway.new
  end

  def self.backfill_data_warehouse_gateway
    @backfill_data_warehouse_gateway ||=
      Gateway::BackfillDataWarehouseGateway.new
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
        lodge_assessment_use_case:,
        validate_assessment_use_case:,
        check_assessor_belongs_to_scheme_use_case:,
        check_approved_software_use_case:,
        country_use_case: get_country_for_candidate_assessment_use_case,
      )
  end

  def self.check_assessor_belongs_to_scheme_use_case
    @check_assessor_belongs_to_scheme_use_case ||=
      UseCase::CheckAssessorBelongsToScheme.new(assessors_gateway:)
  end

  def self.check_approved_software_use_case
    @check_approved_software_use_case ||= UseCase::CheckApprovedSoftware.new logger:
  end

  def self.update_assessment_status_use_case
    @update_assessment_status_use_case ||= UseCase::UpdateAssessmentStatus.new(
      assessments_gateway:,
      assessments_search_gateway:,
      assessors_gateway:,
      event_broadcaster:,
    )
  end

  def self.opt_out_assessment_use_case
    @opt_out_assessment_use_case ||= UseCase::OptOutAssessment.new(
      assessments_gateway:,
      assessments_search_gateway:,
      event_broadcaster:,
    )
  end

  def self.update_assessment_address_id_use_case
    @update_assessment_address_id_use_case ||= UseCase::UpdateAssessmentAddressId.new(
      address_base_gateway: address_base_search_gateway,
      assessments_address_id_gateway:,
      assessments_search_gateway:,
      assessments_gateway:,
      event_broadcaster:,
    )
  end

  def self.lodge_assessment_use_case
    @lodge_assessment_use_case ||=
      UseCase::LodgeAssessment.new(
        assessments_gateway:,
        assessments_search_gateway:,
        assessors_gateway:,
        assessments_xml_gateway:,
        assessments_address_id_gateway:,
        related_assessments_gateway:,
        green_deal_plans_gateway:,
        get_canonical_address_id_use_case:,
        event_broadcaster:,
        search_address_gateway:,
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

  def self.import_green_deal_fuel_price_use_case
    @import_green_deal_fuel_price_use_case ||= UseCase::ImportGreenDealFuelPrice.new(
      green_deal_fuel_price_gateway,
    )
  end

  def self.get_canonical_address_id_use_case
    @get_canonical_address_id_use_case ||= UseCase::GetCanonicalAddressId.new(
      address_base_search_gateway:,
      assessments_address_id_gateway:,
      assessments_search_gateway:,
    )
  end

  def self.get_country_for_postcode_use_case
    @get_country_for_postcode_use_case ||= UseCase::GetCountryForPostcode.new(
      address_base_country_gateway:,
    )
  end

  def self.get_country_for_candidate_assessment_use_case
    @get_country_for_candidate_assessment_use_case = UseCase::GetCountryForCandidateLodgement.new(
      get_canonical_address_id_use_case:,
      get_country_for_postcode_use_case:,
      address_base_country_gateway:,
    )
  end

  def self.bulk_insert_search_address_use_case
    @bulk_insert_search_address_use_case = UseCase::BulkInsertSearchAddress.new(
      search_address_gateway,
    )
  end

  def self.green_deal_fuel_price_gateway
    @green_deal_fuel_price_gateway ||= Gateway::GreenDealFuelPriceGateway.new
  end

  def self.add_green_deal_plan_use_case
    @add_green_deal_plan_use_case ||=
      UseCase::AddGreenDealPlan.new(
        assessments_search_gateway:,
        green_deal_plans_gateway:,
        event_broadcaster:,
      )
  end

  def self.update_green_deal_plan_use_case
    @update_green_deal_plan_use_case ||=
      UseCase::UpdateGreenDealPlan.new(
        green_deal_plans_gateway:,
        event_broadcaster:,
      )
  end

  def self.delete_green_deal_plan_use_case
    @delete_green_deal_plan_use_case ||=
      UseCase::DeleteGreenDealPlan.new(
        green_deal_plans_gateway:,
        event_broadcaster:,
      )
  end

  def self.add_assessor_use_case
    @add_assessor_use_case ||=
      UseCase::AddAssessor.new(
        schemes_gateway:,
        assessors_gateway:,
        assessors_status_events_gateway:,
        event_broadcaster:,
      )
  end

  def self.fetch_active_schemes_use_case
    @fetch_active_schemes_use_case ||=
      UseCase::FetchActiveSchemesId.new(schemes_gateway)
  end

  def self.find_assessments_by_street_name_and_town
    @find_assessments_by_street_name_and_town ||=
      UseCase::FindAssessmentsByStreetNameAndTown.new(assessments_search_gateway)
  end

  def self.fetch_assessment_for_bus_use_case
    @fetch_assessment_for_bus_use_case ||=
      UseCase::FetchAssessmentForBus.new(
        bus_gateway: boiler_upgrade_scheme_gateway,
        summary_use_case: assessment_summary_fetch_use_case,
        domestic_digest_gateway:,
      )
  end

  def self.find_assessments_for_bus_by_address_use_case
    @find_assessments_for_bus_by_address_use_case ||=
      UseCase::FindAssessmentsForBusByAddress.new(
        bus_gateway: boiler_upgrade_scheme_gateway,
        summary_use_case: assessment_summary_fetch_use_case,
        domestic_digest_gateway:,
      )
  end

  def self.find_assessments_for_bus_by_uprn_use_case
    @find_assessments_for_bus_by_uprn_use_case ||=
      UseCase::FindAssessmentsForBusByUprn.new(
        bus_gateway: boiler_upgrade_scheme_gateway,
        summary_use_case: assessment_summary_fetch_use_case,
        domestic_digest_gateway:,
      )
  end

  def self.fetch_retrofit_funding_scheme_details_use_case
    @fetch_retrofit_funding_scheme_details_use_case ||=
      UseCase::FetchAssessmentForRetrofitFundingScheme.new(
        retrofit_funding_scheme_gateway:,
        assessments_search_gateway:,
        domestic_digest_gateway:,
      )
  end

  def self.fetch_assessment_for_hera_use_case
    @fetch_assessment_for_hera_use_case ||=
      UseCase::FetchAssessmentForHera.new(
        domestic_digest_gateway:,
        summary_use_case: assessment_summary_fetch_use_case,
      )
  end

  def self.fetch_assessment_for_heat_pump_check_use_case
    @fetch_assessment_for_heat_pump_check_use_case ||=
      UseCase::FetchAssessmentForHeatPumpCheck.new(
        domestic_digest_gateway:,
        summary_use_case: assessment_summary_fetch_use_case,
      )
  end

  def self.fetch_assessment_for_warm_home_discount_service_use_case
    @fetch_assessment_for_warm_home_discount_service_use_case ||=
      UseCase::FetchAssessmentForWarmHomeDiscountService.new(
        domestic_digest_gateway:,
        summary_use_case: assessment_summary_fetch_use_case,
      )
  end

  def self.assessment_summary_fetch_use_case
    @assessment_summary_fetch_use_case ||=
      UseCase::AssessmentSummary::Fetch.new(
        search_gateway: assessments_search_gateway,
        xml_gateway: assessments_xml_gateway,
      )
  end

  def self.fetch_assessment_for_eco_plus_use_case
    @fetch_assessment_for_eco_plus_use_case ||=
      UseCase::FetchAssessmentForEcoPlus.new(
        domestic_digest_gateway:,
        assessments_search_gateway:,
      )
  end

  def self.backfill_data_warehouse_use_case
    @backfill_data_warehouse_use_case ||=
      UseCase::BackfillDataWarehouse.new(
        backfill_gateway: backfill_data_warehouse_gateway,
        data_warehouse_queues_gateway:,
      )
  end

  def self.backfill_data_warehouse_by_events_use_case
    @backfill_data_warehouse_by_events_use_case ||=
      UseCase::BackfillDataWarehouseByEvents.new(
        audit_logs_gateway:,
        data_warehouse_queues_gateway:,
      )
  end

  def self.find_domestic_epcs_by_address
    @find_domestic_epcs_by_address ||=
      UseCase::FindDomesticEpcByAddress.new(gateway: domestic_epc_search_gateway)
  end

  def self.get_assessment_count_by_scheme_name_type
    UseCase::GetAssessmentCountBySchemeNameAndType.new
  end

  def self.get_assessment_count_by_region_type
    UseCase::GetAssessmentCountByRegionAndType.new
  end

  def self.get_assessment_rrns_by_scheme_type
    UseCase::GetAssessmentRrnsBySchemeNameAndType.new
  end

  def self.process_postcode_csv
    @process_postcode_csv ||= UseCase::ProcessPostcodeCsv.new(geolocation_gateway)
  end

  def self.storage_configuration_reader(bucket_name:)
    Gateway::StorageConfigurationReader.new(
      bucket_name:,
    )
  end

  def self.delete_geolocation_tables
    @delete_geolocation_tables ||=
      UseCase::DeleteGeolocationTables.new(geolocation_gateway)
  end

  def self.update_assessments_from_landmark(bucket_name:)
    @update_assessments_from_landmark ||= UseCase::UpdateAssessmentsFromLandmark.new(assessments_gateway:, storage_gateway: storage_gateway(bucket_name:))
  end

  def self.add_country_id_from_address
    @add_country_id_from_address ||= UseCase::AddCountryIdFromAddress.new(country_gateway)
  end

  def self.geolocation_gateway
    @geolocation_gateway ||= Gateway::PostcodeGeolocationGateway.new
  end

  def self.country_gateway
    @country_gateway ||= Gateway::CountryGateway.new
  end

  def self.storage_gateway(bucket_name:)
    Gateway::StorageGateway.new(
      storage_config:
        storage_configuration_reader(
          bucket_name:,
        ).get_configuration,
    )
  end

  def self.data_warehouse_queues_gateway
    @data_warehouse_queues_gateway ||= Gateway::DataWarehouseQueuesGateway.new
  end

  def self.search_address_gateway
    @search_address_gateway ||= Gateway::SearchAddressGateway.new
  end

  def self.audit_logs_gateway
    @audit_logs_gateway ||= Gateway::AuditLogsGateway.new
  end

  def self.logger
    return @logger unless @logger.nil?

    @logger = Logger.new($stdout)
    @logger.level = Logger::ERROR

    @logger
  end

  def self.event_broadcaster
    return @event_broadcaster unless @event_broadcaster.nil?

    @event_broadcaster = Events::Broadcaster.new(logger:)
    Events::Listener.new(@event_broadcaster).attach_listeners

    @event_broadcaster
  end

  # Clears out all memoized service instances. Useful for tests.
  def self.clear!
    instance_variables.each { |variable| instance_variable_set variable, nil }
  end
end
