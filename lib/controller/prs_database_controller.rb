module Controller
  class PrsDatabaseController < Controller::BaseController
    SEARCH_SCHEMA = {
      oneOf: [
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

    get "/api/prsdatabase/assessments/search", auth_token_has_all: ["prsdatabase:assessment:search"] do
      filters = params_body(SEARCH_SCHEMA).slice(:rrn, :uprn)
      result = ApiFactory.fetch_assessment_for_prs_database_use_case.execute(**filters)
      json_api_response code: 200, data: result.to_hash
    rescue UseCase::FetchAssessmentForPrsDatabase::NotFoundException
      error_response 404, "NOT_FOUND", "No assessment details could be found for that query"
    rescue UseCase::FetchAssessmentForPrsDatabase::InvalidAssessmentTypeException
      error_response 404, "NOT_FOUND", "The requested assessment type is not SAP or RdSAP"
    rescue Boundary::Json::ValidationError => e
      message = case e.failed_properties.count
                when 0
                  "The search query was invalid - please check the provided parameters"
                when 1
                  "The value provided for the #{e.failed_properties.first} parameter in the search query was not valid"
                else
                  "The values provided for the following parameters were not valid: #{e.failed_properties.join(', ')}"
                end
      error_response 400, "BAD_REQUEST", message
    rescue StandardError => e
      server_error e
    end
  end
end
