require_relative 'helpers/toggles'
require_relative 'use_cases/get_all_schemes'
require_relative 'use_cases/add_new_scheme'

class AssessorService < Sinatra::Base
  attr_reader :toggles

  def initialize(toggles = false)
    super

    @toggles = toggles || Toggles.new
  end

  get '/' do
    'Hello world!'
  end

  get '/healthcheck' do
    status 200
  end

  get '/schemes' do
    content_type :json

    @use_case = GetAllSchemes.new
    @use_case.execute.to_json
  end

  post '/schemes' do
    @use_case = AddNewScheme.new
    @use_case.execute('CIBSE')
  end
end
