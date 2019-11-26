require 'sinatra/base'
require_relative 'helpers/toggles'
require_relative 'use_cases/get_all_schemes'

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
    @scheme = Scheme.create({:name => 'CIBSE'})
  end 
end
