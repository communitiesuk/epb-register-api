module Controller
  class DecSummaryController < Controller::BaseController
    get "/api/dec_summary/:assessment_id",
        auth_token_has_all: %w[dec_summary:fetch] do
      json_api_response(
        code: 200,
        data: UseCase::FetchDecSummary.new.execute(params[:assessment_id]),
      )
    rescue UseCase::FetchDecSummary::AssessmentNotFound
      not_found_error("Assessment not found")
    rescue UseCase::FetchDecSummary::AssessmentGone
      gone_error("Assessment not for issue")
    rescue Helper::RrnHelper::RrnNotValid
      error_response 400, "INVALID_REQUEST", "The requested assessment id is not valid"
    rescue UseCase::FetchDecSummary::AssessmentNotDec
      error_response 403, "NOT_A_DEC", "Assessment is not a DEC"
    rescue ViewModel::DecSummaryWrapper::AssessmentNotSupported
      error_response 400, "INVALID_REQUEST", "Unsupported schema type"
    end
  end
end
