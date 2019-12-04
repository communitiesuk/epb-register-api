# frozen_string_literal: true

require_relative 'helper/toggles'
require_relative 'container'
require 'sinatra/cross_origin'

class AssessorService < Sinatra::Base
  STATUS_CODES = {
    '400' => [PG::UniqueViolation, ActiveRecord::RecordNotUnique],
    '401' => [JSON::ParserError]
  }.freeze

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

  get '/api/schemes' do
    content_type :json
    all_schemes = @container.get_object(:get_all_schemes_use_case).execute
    @json_helper.convert_to_json(all_schemes)
  end

  post '/api/schemes' do
    content_type :json
    request_body = @json_helper.convert_to_ruby_hash(request.body.read.to_s)
    result =
      @container.get_object(:add_new_scheme_use_case).execute(
        request_body[:name]
      )

    status 201
    @json_helper.convert_to_json(result)
  rescue StandardError => e
    handle_exception(e)
  end

  put '/api/schemes/:scheme_id/assessors/:scheme_assessor_id' do
    scheme_id = params['scheme_id']
    scheme_assessor_id = params['scheme_assessor_id']
    assessor_details = @json_helper.convert_to_ruby_hash(request.body.read.to_s)
    created_assessor =
      @container.get_object(:add_assessor_use_case).execute(
        scheme_id,
        scheme_assessor_id,
        assessor_details
      )

    status 201
    @json_helper.convert_to_json(created_assessor)
  rescue Exception => e
    case e
    when UseCase::AddAssessor::SchemeNotFoundException
      status 404
    when UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
      status 409
    else
      status 400
    end
  end

  private

  def handle_exception(error)
    return status 400 if STATUS_CODES['400'].include?(error.class)
    return status 401 if STATUS_CODES['401'].include?(error.class)

    status 500
  end
end
