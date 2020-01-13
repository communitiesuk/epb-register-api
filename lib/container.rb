require 'sinatra/activerecord'

class Container
  def initialize
    schemes_gateway = Gateway::SchemesGateway.new
    assessors_gateway = Gateway::AssessorsGateway.new
    add_new_scheme_use_case = UseCase::AddScheme.new(schemes_gateway)
    get_all_schemes_use_case = UseCase::FetchSchemes.new(schemes_gateway)
    add_assessor_use_case =
      UseCase::AddAssessor.new(schemes_gateway, assessors_gateway)
    fetch_assessor_use_case =
      UseCase::FetchAssessor.new(assessors_gateway, schemes_gateway)
    migrate_domestic_epc_use_case = UseCase::MigrateDomesticEpc.new

    @objects = {
      schemes_gateway: schemes_gateway,
      add_new_scheme_use_case: add_new_scheme_use_case,
      get_all_schemes_use_case: get_all_schemes_use_case,
      add_assessor_use_case: add_assessor_use_case,
      fetch_assessor_use_case: fetch_assessor_use_case,
      migrate_domestic_epc_use_case: migrate_domestic_epc_use_case
    }
  end

  def get_object(key)
    @objects[key]
  end
end
