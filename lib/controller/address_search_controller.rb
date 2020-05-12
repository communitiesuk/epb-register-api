module Controller
  class AddressSearchController < Controller::BaseController
    SEARCH_SCHEMA = {
      type: "object",
      required: %w[buildingReferenceNumber],
      properties: {
        buildingReferenceNumber: {
          type: "string",
          pattern: "^RRN-(\\d{4}-){4}\\d{4}$",
        },
      },
    }.freeze

    get "/api/address/search", jwt_auth: %w[address:search] do
      params_body SEARCH_SCHEMA

    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, "INVALID_REQUEST", e.message)
      else
        server_error(e)
      end
    end
  end
end
