require 'sinatra/activerecord'

class Container
  def initialize
    schemes_gateway = Gateway::SchemesGateway.new

    assessors_gateway = Gateway::AssessorsGateway.new

    domestic_energy_assessments_gateway =
      Gateway::DomesticEnergyAssessmentsGateway.new

    postcode_gateway = Gateway::PostcodesGateway.new

    add_new_scheme_use_case = UseCase::AddScheme.new(schemes_gateway)
    get_all_schemes_use_case = UseCase::FetchSchemes.new(schemes_gateway)

    add_assessor_use_case =
      UseCase::AddAssessor.new(schemes_gateway, assessors_gateway)
    fetch_assessor_use_case =
      UseCase::FetchAssessor.new(assessors_gateway, schemes_gateway)

    migrate_domestic_energy_assessment_use_case =
      UseCase::MigrateDomesticEnergyAssessment.new(
        domestic_energy_assessments_gateway,
        assessors_gateway
      )
    fetch_domestic_energy_assessment_use_case =
      UseCase::FetchDomesticEnergyAssessment.new(
        domestic_energy_assessments_gateway,
        assessors_gateway
      )

    find_assessors_by_postcode_use_case =
      UseCase::FindAssessorsByPostcode.new(
        postcode_gateway,
        assessors_gateway,
        schemes_gateway
      )
    find_assessors_by_name_use_case =
      UseCase::FindAssessorsByName.new(assessors_gateway, schemes_gateway)

    find_assessments_by_postcode_use_case =
      UseCase::FindAssessmentsByPostcode.new(
        domestic_energy_assessments_gateway
      )
    find_assessments_by_assessment_id_use_case =
      UseCase::FindAssessmentsByAssessmentId.new(
        domestic_energy_assessments_gateway
      )
    find_assessments_by_street_name_and_town_use_case =
      UseCase::FindAssessmentsByStreetNameAndTown.new(
        domestic_energy_assessments_gateway
      )
    fetch_assessor_list_use_case =
      UseCase::FetchAssessorList.new(assessors_gateway, schemes_gateway)

    lodge_assessment_use_case =
      UseCase::LodgeAssessment.new(
        domestic_energy_assessments_gateway,
        assessors_gateway
      )

    @objects = {
      schemes_gateway: schemes_gateway,
      add_new_scheme_use_case: add_new_scheme_use_case,
      get_all_schemes_use_case: get_all_schemes_use_case,
      add_assessor_use_case: add_assessor_use_case,
      fetch_assessor_use_case: fetch_assessor_use_case,
      migrate_domestic_energy_assessment_use_case:
        migrate_domestic_energy_assessment_use_case,
      fetch_domestic_energy_assessment_use_case:
        fetch_domestic_energy_assessment_use_case,
      find_assessors_by_postcode_use_case: find_assessors_by_postcode_use_case,
      find_assessors_by_name_use_case: find_assessors_by_name_use_case,
      fetch_assessor_list_use_case: fetch_assessor_list_use_case,
      find_assessments_by_postcode_use_case:
        find_assessments_by_postcode_use_case,
      find_assessments_by_assessment_id_use_case:
        find_assessments_by_assessment_id_use_case,
      find_assessments_by_street_name_and_town_use_case:
        find_assessments_by_street_name_and_town_use_case,
      lodge_assessment_use_case: lodge_assessment_use_case
    }
  end

  def get_object(key)
    @objects[key]
  end
end
