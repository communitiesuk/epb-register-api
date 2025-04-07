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
      filters = params_body SEARCH_SCHEMA

      use_case, execute_params =
        if filters.key? :rrn
          [ApiFactory.fetch_assessment_for_prs_database_use_case, filters.slice(:rrn)]
        elsif filters.key? :uprn
          [ApiFactory.fetch_assessment_for_prs_database_use_case, filters.slice(:uprn)]
        end

      result = use_case.execute(**execute_params)
      case result
      when Domain::AssessmentForPrsDatabaseDetails
        json_api_response code: 200, data: result.to_hash
      when nil
        raise Sinatra::NotFound
      end
    rescue StandardError => e
      case e
      when UseCase::FetchAssessmentForPrsDatabase::NotFoundException
        error_response 404, "NOT_FOUND", "No assessment details could be found for that query"
      when UseCase::FetchAssessmentForPrsDatabase::AssessmentGone
        error_response 404, "NOT_FOUND", "No assessment details could be found for that query"
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
      when UseCase::FetchAssessmentForPrsDatabase::InvalidAssessmentTypeException
        error_response 400, "INVALID_REQUEST", "The requested assessment type is not SAP or RdSAP"
      else
        server_error e
      end
    end
  end
end
