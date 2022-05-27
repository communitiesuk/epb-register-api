module Controller
  class DomesticEpcSearchController < Controller::BaseController
    SEARCH_SCHEMA = {
      oneOf: [
        {
          type: "object",
          required: %w[postcode buildingNameOrNumber],
          properties: {
            postcode: {
              type: "string",
              pattern: Helper::RegexHelper::POSTCODE,
            },
            buildingNameOrNumber: {
              type: "string",
            },
          },
        },
      ],
    }.freeze

    class NotImplementedError < StandardError; end

    get "/api/assessments/domestic-epcs/search", auth_token_has_all: ["domestic_epc:assessment:search"] do
      raise NotImplementedError unless Helper::Toggles.enabled? "register-api-domestic-epc-search-endpoint-enabled"

      params_body SEARCH_SCHEMA
      use_case = ApiFactory.find_domestic_epcs_by_address
      execute_params = { postcode: params[:postcode], building_identifier: params[:buildingNameOrNumber] }

      result = use_case.execute(**execute_params)
      raise Sinatra::NotFound if result.nil?

      status = 200
      data = result.to_hash
      json_api_response(code: status, data: data)
    rescue StandardError => e
      case e
      when Sinatra::NotFound
        error_response 404, "NOT_FOUND", "No domestic assessments could be found for that query"
      when Boundary::Json::ValidationError
        error_response 400, "BAD_REQUEST",
                       case e.failed_properties.count
                       when 0
                         "The search query was invalid - please check the provided parameters"
                       when 1
                         "The value provided for the #{e.failed_properties.first} parameter in the search query was not valid"
                       else
                         "The values provided for the following parameters were not valid: #{e.failed_properties.join(', ')}"
                       end
      when NotImplementedError
        error_response 501, "NOT_IMPLEMENTED", "This endpoint is not implemented"
      else
        server_error e
      end
    end
  end
end
