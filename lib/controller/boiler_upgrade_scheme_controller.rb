module Controller
  class BoilerUpgradeSchemeController < Controller::BaseController
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
        {
          type: "object",
          required: %w[uprn],
          properties: {
            uprn: {
              type: "string",
              pattern: Helper::RegexHelper::UPRN,
            },
          },
        },
        {
          type: "object",
          required: %w[rrn],
          properties: {
            rrn: {
              type: "string",
              pattern: Helper::RegexHelper::RRN,
            },
          },
        },
      ],
    }.freeze

    class NotImplementedError < StandardError; end

    get "/api/bus/assessments/latest/search", auth_token_has_all: ["bus:assessment:search"] do
      raise NotImplementedError unless Helper::Toggles.enabled? "bus-endpoint-enabled"

      filters = params_body SEARCH_SCHEMA

      use_case, execute_params =
        if filters.key? :rrn
          [ApiFactory.fetch_assessment_for_bus_use_case, filters.slice(:rrn)]
        elsif filters.key? :postcode
          [ApiFactory.find_assessments_for_bus_by_address_use_case, { postcode: params[:postcode], building_identifier: params[:buildingNameOrNumber] }]
        elsif filters.key? :uprn
          [ApiFactory.find_assessments_for_bus_by_uprn_use_case, filters.slice(:uprn)]
        end

      result = use_case.execute(**execute_params)
      status, data = case result
                     when Domain::AssessmentBusDetails
                       [200, result.to_hash]
                     when Domain::AssessmentReferenceList
                       [300, { links: { assessments: result.references } }]
                     when nil
                       raise Sinatra::NotFound
                     end
      json_api_response(code: status, data:)
    rescue StandardError => e
      case e
      when Sinatra::NotFound
        error_response 404, "NOT_FOUND", "No assessment details relevant to the BUS could be found for that query"
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
