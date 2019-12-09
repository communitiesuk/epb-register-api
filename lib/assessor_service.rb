# frozen_string_literal: true

require_relative 'helper/toggles'
require_relative 'container'
require 'sinatra/cross_origin'

class AssessorService < Sinatra::Base
  attr_reader :toggles

  def initialize(toggles = false)
    super
    @json_helper = Helper::JsonHelper.new
    @toggles = toggles || Toggles.new
    @container = Container.new
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    also_reload 'lib/**/*.rb'
  end

  configure do
    enable :cross_origin
    set :protection, except: %i[remote_token]
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] =
      'Content-Type, Cache-Control, Accept'
  end

  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Methods'] =
      'HEAD, GET, PUT, OPTIONS, DELETE, POST'
    200
  end

  get '/' do
    redirect '/api'
  end

  get '/api' do
    content_type :json

    {
      links: { apispec: 'https://mhclg-epb-swagger.london.cloudapps.digital' }
    }.to_json
  end

  get '/healthcheck' do
    status 200
  end

  use Controller::AssessorController
  use Controller::SchemesController
end
