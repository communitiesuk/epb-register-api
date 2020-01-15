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
        domestic_energy_assessments_gateway
      )
    fetch_domestic_energy_assessment_use_case =
      UseCase::FetchDomesticEnergyAssessment.new(
        domestic_energy_assessments_gateway
      )
    find_assessors_use_case =
      UseCase::FindAssessors.new(postcode_gateway, assessors_gateway, schemes_gateway)

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
      find_assessors_use_case: find_assessors_use_case
    }
  end

  def get_object(key)
    @objects[key]
  end
end
