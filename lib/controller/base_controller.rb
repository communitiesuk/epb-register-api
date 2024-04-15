require_relative "../helper/toggles"
require "sinatra/cross_origin"
require "epb-auth-tools"
require "epb_view_models"
require "nokogiri"
require "sinatra/activerecord"
require "csv"

module Controller
  class BaseController < Sinatra::Base
    def initialize(*args)
      super
      @xml_helper = Helper::XmlHelper.new
      @json_helper = Helper::JsonHelper.new
      @logger = ApiFactory.logger
      @events = Helper::EventLogger.new
    end

    configure :development do
      require "sinatra/reloader"
      register Sinatra::Reloader
      also_reload "lib/**/*.rb"
    end

    configure do
      enable :cross_origin
      set :protection, except: %i[remote_token path_traversal]
    end

    before do
      raise MaintenanceMode if request.path != "/healthcheck" && Helper::Toggles.enabled?("register-api-maintenance-mode")

      raise ReadOnlyMode if !request.get? && Helper::Toggles.enabled?("register-api-read-only-mode")

      unless ENV["EPB_API_DOCS_URL"].nil?
        response.headers["Access-Control-Allow-Origin"] = ENV["EPB_API_DOCS_URL"]
        response.headers["Vary"] = "Origin"
        response.headers["Access-Control-Allow-Credentials"] = "true"
      end

      response.headers["Access-Control-Allow-Headers"] =
        "Content-Type, Cache-Control, Accept, Authorization, X-Requested-With"
    end

    set(:auth_token_has_all) do |*scopes|
      condition do
        token = Auth::Sinatra::Conditional.process_request env
        unless token.scopes?(scopes)
          forbidden(
            "UNAUTHORISED",
            "You are not authorised to perform this request",
          )
        end
        env[:auth_token] = token
      rescue Auth::Errors::Error => e
        content_type :json
        halt 401, { errors: [{ code: e }] }.to_json
      end
    end

    set(:auth_token_has_one_of) do |*scopes|
      condition do
        token = Auth::Sinatra::Conditional.process_request env
        has_a_scope = false
        scopes.each do |scope|
          has_a_scope = token.scope? scope
          break if has_a_scope
        end
        unless has_a_scope
          forbidden(
            "UNAUTHORISED",
            "You are not authorised to perform this request",
          )
        end
        env[:auth_token] = token
      rescue Auth::Errors::Error => e
        content_type :json
        halt 401, { errors: [{ code: e }] }.to_json
      end
    end

    def xml_request_body(schema)
      @xml_helper.convert_to_hash(request.body.read.to_s, schema:)
    end

    def params_body(schema)
      @json_helper.convert_to_ruby_hash(params.to_json, schema:)
    end

    def request_body(schema)
      @json_helper.convert_to_ruby_hash(request.body.read.to_s, schema:)
    end

    def relevant_request_headers(request)
      relevant_keys = [:auth_token]
      request.env.select { |key, _value| relevant_keys.include?(key) }.to_json
    end

    def json_response(object, code = 200)
      content_type :json
      status code

      ActiveRecord::Base.connection_handler.clear_active_connections!(:all)

      @json_helper.convert_to_json(object)
    end

    def json_api_response(
      code: 200,
      data: {},
      meta: {},
      burrow_key: false,
      data_key: :data
    )
      if burrow_key
        data, meta = meta, data
        data[burrow_key] = meta.delete(data_key)
      end

      json_response({ data:, meta: }, code)
    end

    def xml_response(xml, code = 200)
      content_type :xml
      status code

      ActiveRecord::Base.connection_handler.clear_active_connections!(:all)

      body xml
    end

    def error_response(response_code, error_code, title)
      json_response({ errors: [{ code: error_code, title: }] }, response_code)
    end

    def server_error(exception)
      Sentry.capture_exception(exception) if defined?(Sentry)

      message =
        exception.methods.include?(:message) ? exception.message : exception

      error = { type: exception.class.name, message: }

      if exception.methods.include? :backtrace
        error[:backtrace] = exception.backtrace
      end

      @logger.error JSON.generate(error)

      ActiveRecord::Base.connection_handler.clear_active_connections!(:all)

      error_response(500, "SERVER_ERROR", message)
    end

    def not_found_error(message)
      error_response(404, "NOT_FOUND", message)
    end

    def gone_error(message)
      error_response(410, "GONE", message)
    end

    def forbidden(error_code, title, code = 403)
      halt json_response({ errors: [{ code: error_code, title: }] }, code)
    end

    def boolean_parameter_true?(key)
      params[key].blank? || params[key] == "true" if params.key?(key)
    end

    error Sinatra::NotFound do
      content_type :text
      error_response(404, "NOT_FOUND", "Not found")
    end

    class ScheduledDowntimeError < RuntimeError; end

    class MaintenanceMode < ScheduledDowntimeError; end
    error Controller::BaseController::MaintenanceMode do
      error_response(503, "SERVICE_UNAVAILABLE", "The service is currently under maintenance")
    end

    class ReadOnlyMode < ScheduledDowntimeError; end
    error Controller::BaseController::ReadOnlyMode do
      error_response(503, "SERVICE_UNAVAILABLE", "The service is currently only accepting GET requests")
    end
  end
end

module RequestModule
  class << self
    attr_accessor :relevant_request_headers
  end
end
