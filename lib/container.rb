require "sinatra/activerecord"

class Container
  def initialize
    add_assessor_use_case = UseCase::AddAssessor.new
    fetch_assessor_use_case = UseCase::FetchAssessor.new

    migrate_assessment_use_case = UseCase::MigrateAssessment.new
    fetch_assessment_use_case = UseCase::FetchAssessment.new

    add_green_deal_plan_use_case = UseCase::AddGreenDealPlan.new

    fetch_renewable_heat_incentive_use_case =
      UseCase::FetchRenewableHeatIncentive.new

    find_assessors_by_postcode_use_case = UseCase::FindAssessorsByPostcode.new
    find_assessors_by_name_use_case = UseCase::FindAssessorsByName.new

    find_assessments_by_postcode_use_case =
        UseCase::FindAssessmentsByPostcode.new
    find_assessments_by_assessment_id_use_case =
        UseCase::FindAssessmentsByAssessmentId.new
    find_assessments_by_street_name_and_town_use_case =
      UseCase::FindAssessmentsByStreetNameAndTown.new
    fetch_assessor_list_use_case = UseCase::FetchAssessorList.new

    update_assessments_status_use_case = UseCase::UpdateAssessmentStatus.new

    validate_assessment_use_case = UseCase::ValidateAssessment.new

    lodge_assessment_use_case = UseCase::LodgeAssessment.new

    check_assessor_belongs_to_scheme_use_case =
      UseCase::CheckAssessorBelongsToScheme.new

    search_addresses_by_address_id_use_case =
      UseCase::SearchAddressesByAddressId.new

    search_addresses_by_postcode_use_case =
      UseCase::SearchAddressesByPostcode.new

    search_addresses_by_street_and_town_use_case =
      UseCase::SearchAddressesByStreetAndTown.new

    validate_and_lodge_assessment_use_case =
      UseCase::ValidateAndLodgeAssessment.new(
        validate_assessment_use_case,
        lodge_assessment_use_case,
        check_assessor_belongs_to_scheme_use_case,
      )

    @objects = {
      add_green_deal_plan_use_case: add_green_deal_plan_use_case,
      add_assessor_use_case: add_assessor_use_case,
      fetch_assessor_use_case: fetch_assessor_use_case,
      migrate_assessment_use_case: migrate_assessment_use_case,
      fetch_assessment_use_case: fetch_assessment_use_case,
      fetch_renewable_heat_incentive_use_case:
        fetch_renewable_heat_incentive_use_case,
      find_assessors_by_postcode_use_case: find_assessors_by_postcode_use_case,
      find_assessors_by_name_use_case: find_assessors_by_name_use_case,
      fetch_assessor_list_use_case: fetch_assessor_list_use_case,
      find_assessments_by_postcode_use_case:
        find_assessments_by_postcode_use_case,
      find_assessments_by_assessment_id_use_case:
        find_assessments_by_assessment_id_use_case,
      find_assessments_by_street_name_and_town_use_case:
        find_assessments_by_street_name_and_town_use_case,
      lodge_assessment_use_case: lodge_assessment_use_case,
      check_assessor_belongs_to_scheme_use_case:
        check_assessor_belongs_to_scheme_use_case,
      validate_assessment_use_case: validate_assessment_use_case,
      validate_and_lodge_assessment_use_case:
        validate_and_lodge_assessment_use_case,
      search_addresses_by_address_id_use_case:
        search_addresses_by_address_id_use_case,
      search_addresses_by_postcode_use_case:
        search_addresses_by_postcode_use_case,
      search_addresses_by_street_and_town_use_case:
        search_addresses_by_street_and_town_use_case,
      update_assessments_status_use_case: update_assessments_status_use_case,
    }
  end

  def get_object(key)
    @objects[key]
  end
end
