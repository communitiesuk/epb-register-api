# frozen_string_literal: true

module Controller
  class SchemesController < Controller::BaseController
    POST_SCHEMA = {
      type: "object",
      required: %w[name],
      properties: { name: { type: "string" } },
    }.freeze

    get "/api/schemes", jwt_auth: %w[scheme:list] do
      all_schemes = UseCase::FetchSchemes.new.execute
      json_api_response(code: 200, data: all_schemes)
    end

    post "/api/schemes", jwt_auth: %w[scheme:create] do
      new_scheme_details = request_body(POST_SCHEMA)
      result = UseCase::AddScheme.new.execute(new_scheme_details[:name])
      json_api_response(code: 201, data: result)
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError, JSON::ParserError
        error_response(401, "INVALID_REQUEST", e.message)
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

    put "/api/schemes/:scheme_id", jwt_auth: %w[scheme:update] do
      UseCase::UpdateScheme.new.execute(params[:scheme_id])
      status 204

    rescue StandardError => e
      case e
      when UseCase::UpdateScheme::SchemeNotFound
        not_found_error("Scheme not found")
      else
        server_error(e.message)
      end
    end
  end
end
