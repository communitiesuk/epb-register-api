module Controller
  class RetrofitFundingSchemeController < Controller::BaseController
    SCHEMA = {
      type: "object",
      required: %w[uprn],
      properties: {
        uprn: {
          type: "string",
          pattern: Helper::RegexHelper::STRIPPED_UPRN,
        },
      },
    }.freeze

    get "/api/retrofit-funding/assessments", auth_token_has_all: ["retrofit-funding:assessment:fetch"] do
      params_body SCHEMA

      uprn = params[:uprn]

      details = ApiFactory.fetch_retrofit_funding_scheme_details_use_case.execute(uprn)
      case details
      when Domain::AssessmentRetrofitFundingDetails
        json_api_response(
          code: 200,
          data: {
            assessment: details.to_hash,
          },
        )
      when nil
        raise Sinatra::NotFound
      end
    rescue StandardError => e
      case e
      when Sinatra::NotFound
        error_response 404, "NOT_FOUND", "No domestic EPCs found for this UPRN"
      when Boundary::Json::ValidationError
        error_response 400, "BAD_REQUEST", "The UPRN parameter is badly formatted"
      else
        server_error e
      end
    end
  end
end
