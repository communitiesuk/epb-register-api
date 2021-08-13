require_relative "../helper/toggles"
require "sinatra/cross_origin"
require "epb-auth-tools"
require "epb_view_models"
require "nokogiri"
require "sinatra/activerecord"
require "csv"

module Controller
  class BaseController < Sinatra::Base
    attr_reader :toggles

    @toggles = nil

    def initialize(toggles = false)
      super
      @xml_helper = Helper::XmlHelper.new
      @json_helper = Helper::JsonHelper.new
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
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
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Headers"] =
        "Content-Type, Cache-Control, Accept"
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
      @xml_helper.convert_to_hash(request.body.read.to_s, schema)
    end

    def params_body(schema = false)
      @json_helper.convert_to_ruby_hash(params.to_json, schema)
    end

    def request_body(schema = false)
      @json_helper.convert_to_ruby_hash(request.body.read.to_s, schema)
    end

    def json_response(object, code = 200)
      content_type :json
      status code

      ActiveRecord::Base.clear_active_connections!

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

      json_response({ data: data, meta: meta }, code)
    end

    def xml_response(xml, code = 200)
      content_type :xml
      status code

      ActiveRecord::Base.clear_active_connections!

      body xml
    end

    def error_response(response_code, error_code, title)
      json_response({ errors: [{ code: error_code, title: title }] }, response_code)
    end

    def server_error(exception)
      Sentry.capture_exception(exception) if defined?(Sentry)

      message =
        exception.methods.include?(:message) ? exception.message : exception

      error = { type: exception.class.name, message: message }

      if exception.methods.include? :backtrace
        error[:backtrace] = exception.backtrace
      end

      @logger.error JSON.generate(error)

      ActiveRecord::Base.clear_active_connections!

      error_response(500, "SERVER_ERROR", message)
    end

    def not_found_error(message)
      error_response(404, "NOT_FOUND", message)
    end

    def gone_error(message)
      error_response(410, "GONE", message)
    end

    def forbidden(error_code, title, code = 403)
      halt json_response({ errors: [{ code: error_code, title: title }] }, code)
    end

    def boolean_parameter_true?(key)
      params[key].blank? || params[key] == "true" if params.key?(key)
    end

    error Sinatra::NotFound do
      content_type :text
      error_response(404, "NOT_FOUND", "Method not found")
    end
  end
end
