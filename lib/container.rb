require 'sinatra/activerecord'

class Container

  def initialize
    schemes_gateway = Gateway::SchemesGateway.new
    add_new_scheme_use_case = UseCase::AddScheme.new(schemes_gateway)
    get_all_schemes_use_case = UseCase::FetchSchemes.new(schemes_gateway)
    add_assessor_use_case = UseCase::AddAssessor.new(schemes_gateway)

    @objects =
      { schemes_gateway: schemes_gateway,
        add_new_scheme_use_case: add_new_scheme_use_case,
        get_all_schemes_use_case: get_all_schemes_use_case,
        add_assessor_use_case: add_assessor_use_case
      }
  end

  def get_object(key)
    @objects[key]
  end
end
