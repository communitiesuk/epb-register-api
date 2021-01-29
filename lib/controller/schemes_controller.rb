# frozen_string_literal: true

module Controller
  class SchemesController < Controller::BaseController
    SCHEMA = {
      type: "object",
      required: %w[name active],
      properties: {
        name: {
          type: "string",
        },
        active: {
          type: "boolean",
        },
      },
    }.freeze

    get "/api/schemes", auth_token_has_all: %w[scheme:list] do
      all_schemes = UseCase::FetchSchemes.new.execute
      json_api_response(code: 200, data: all_schemes)
    end

    post "/api/schemes", auth_token_has_all: %w[scheme:create] do
      new_scheme_details = request_body(SCHEMA)
      result = UseCase::AddScheme.new.execute(new_scheme_details)
      json_api_response(code: 201, data: result)
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError, JSON::ParserError
        error_response(400, "INVALID_REQUEST", e.message)
      when Gateway::SchemesGateway::DuplicateSchemeException
        error_response(
          400,
          "DUPLICATE_SCHEME",
          "Scheme with this name already exists",
        )
      else
        server_error(e.message)
      end
    end

    put "/api/schemes/:scheme_id", auth_token_has_all: %w[scheme:update] do
      updated_scheme_details = request_body(SCHEMA)
      UseCase::UpdateScheme.new.execute(
        params[:scheme_id],
        updated_scheme_details,
      )
      status 204
    rescue StandardError => e
      case e
      when UseCase::UpdateScheme::SchemeNotFound
        not_found_error("Scheme not found")
      when JSON::Schema::ValidationError, JSON::ParserError
        error_response(400, "INVALID_REQUEST", e.message)
      else
        server_error(e.message)
      end
    end
  end
end
