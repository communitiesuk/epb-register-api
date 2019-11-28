require 'sinatra/activerecord'
require_relative 'gateway/schemes/schemes_gateway'
require_relative 'use_case/fetch_schemes'
require_relative 'use_case/add_scheme'

class Container

  def initialize
    schemes_gateway = SchemesGateway.new
    add_new_scheme_use_case = AddScheme.new(schemes_gateway)
    get_all_schemes_use_case = FetchSchemes.new(schemes_gateway)

    @objects =
      { schemes_gateway: schemes_gateway,
        add_new_scheme_use_case: add_new_scheme_use_case,
        get_all_schemes_use_case: get_all_schemes_use_case }
  end

  def get_object(key)
    @objects[key]
  end
end