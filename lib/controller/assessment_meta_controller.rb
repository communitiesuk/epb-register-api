module Controller
  class AssessmentMetaController < Controller::BaseController
    get "/api/assessments/:assessment_id/meta-data",
        auth_token_has_all: %w[assessmentmetadata:fetch] do
      assessment_id = params[:assessment_id]
      summary = UseCase::AssessmentMeta.new(Gateway::AssessmentMetaGateway.new).execute(assessment_id)

      json_api_response(data: summary)
    rescue StandardError => e
      case e
      when UseCase::AssessmentMeta::NoDataException
        error_response(404, "NOT_FOUND", "Assessment ID did not return any data")
      when ArgumentError
        error_response(400, "INVALID_QUERY", e.message)
      else
        server_error(e)
      end
    end
  end
end
