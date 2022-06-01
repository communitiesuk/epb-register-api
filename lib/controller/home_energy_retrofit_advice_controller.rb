module Controller
  class HomeEnergyRetrofitAdviceController < Controller::BaseController
    SCHEMA = {
      type: "object",
      required: %w[assessmentId],
      properties: {
        assessmentId: {
          type: "string",
          pattern: Helper::RegexHelper::RRN,
        },
      },
    }.freeze

    get "/api/retrofit-advice/assessments/:assessmentId",
        auth_token_has_all: %w[retrofit-advice:assessment:search] do
      params_body SCHEMA

      details = ApiFactory.fetch_assessment_for_hera_use_case.execute(rrn: params[:assessmentId])
      raise Sinatra::NotFound if details.nil?

      json_api_response(
        code: 200,
        data: {
          assessment: details.to_hash,
        },
      )
    rescue StandardError => e
      case e
      when Sinatra::NotFound
        error_response 404, "NOT_FOUND", "No assessment details relevant to the Home Energy Retrofit Advice scheme could be found for that query"
      when Boundary::Json::ValidationError
        error_response 400, "BAD_REQUEST", "The value provided for the assessment ID (RRN) in the endpoint URL was not valid"
      else
        server_error e
      end
    end
  end
end
