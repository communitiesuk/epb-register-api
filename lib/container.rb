require "sinatra/activerecord"

class Container
  def initialize
    schemes_gateway = Gateway::SchemesGateway.new

    assessors_gateway = Gateway::AssessorsGateway.new

    address_search_gateway = Gateway::AddressSearchGateway.new

    assessments_gateway = Gateway::AssessmentsGateway.new

    postcode_gateway = Gateway::PostcodesGateway.new

    assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new

    add_new_scheme_use_case = UseCase::AddScheme.new(schemes_gateway)
    get_all_schemes_use_case = UseCase::FetchSchemes.new(schemes_gateway)

    add_assessor_use_case =
      UseCase::AddAssessor.new(schemes_gateway, assessors_gateway)
    fetch_assessor_use_case =
      UseCase::FetchAssessor.new(assessors_gateway, schemes_gateway)

    migrate_assessment_use_case =
      UseCase::MigrateAssessment.new(assessments_gateway, assessors_gateway)
    fetch_assessment_use_case =
      UseCase::FetchAssessment.new(assessments_gateway, assessors_gateway)

    find_assessors_by_postcode_use_case =
      UseCase::FindAssessorsByPostcode.new(
        postcode_gateway,
        assessors_gateway,
        schemes_gateway,
      )
    find_assessors_by_name_use_case =
      UseCase::FindAssessorsByName.new(assessors_gateway, schemes_gateway)

    find_assessments_by_postcode_use_case =
      UseCase::FindAssessmentsByPostcode.new(assessments_gateway)
    find_assessments_by_assessment_id_use_case =
      UseCase::FindAssessmentsByAssessmentId.new(assessments_gateway)
    find_assessments_by_street_name_and_town_use_case =
      UseCase::FindAssessmentsByStreetNameAndTown.new(assessments_gateway)
    fetch_assessor_list_use_case =
      UseCase::FetchAssessorList.new(assessors_gateway, schemes_gateway)

    validate_assessment_use_case = UseCase::ValidateAssessment.new

    lodge_assessment_use_case =
      UseCase::LodgeAssessment.new(assessments_gateway, assessors_gateway)

    check_assessor_belongs_to_scheme_use_case =
      UseCase::CheckAssessorBelongsToScheme.new(assessors_gateway)

    search_addresses_by_building_reference_number_use_case =
      UseCase::SearchAddressesByBuildingReferenceNumber.new address_search_gateway

    search_addresses_by_postcode_use_case =
      UseCase::SearchAddressesByPostcode.new address_search_gateway

    search_addresses_by_street_and_town_use_case =
      UseCase::SearchAddressesByStreetAndTown.new address_search_gateway

    validate_and_lodge_assessment_use_case =
      UseCase::ValidateAndLodgeAssessment.new(
        validate_assessment_use_case,
        lodge_assessment_use_case,
        check_assessor_belongs_to_scheme_use_case,
        assessments_xml_gateway,
      )

    @objects = {
      schemes_gateway: schemes_gateway,
      address_search_gateway: address_search_gateway,
      add_new_scheme_use_case: add_new_scheme_use_case,
      get_all_schemes_use_case: get_all_schemes_use_case,
      add_assessor_use_case: add_assessor_use_case,
      fetch_assessor_use_case: fetch_assessor_use_case,
      migrate_assessment_use_case: migrate_assessment_use_case,
      fetch_assessment_use_case: fetch_assessment_use_case,
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
      search_addresses_by_building_reference_number_use_case:
        search_addresses_by_building_reference_number_use_case,
      search_addresses_by_postcode_use_case:
        search_addresses_by_postcode_use_case,
      search_addresses_by_street_and_town_use_case:
        search_addresses_by_street_and_town_use_case,
    }
  end

  def get_object(key)
    @objects[key]
  end
end
