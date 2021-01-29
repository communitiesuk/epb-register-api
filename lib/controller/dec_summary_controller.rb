module Controller
  class DecSummaryController < Controller::BaseController
    get "/api/dec_summary/:assessment_id",
        auth_token_has_all: %w[dec_summary:fetch] do
      json_api_response(
        code: 200,
        data: UseCase::FetchDecSummary.new.execute(params[:assessment_id]),
      )
    rescue StandardError => e
      case e
      when UseCase::FetchDecSummary::AssessmentNotFound
        not_found_error("Assessment not found")
      when UseCase::FetchDecSummary::AssessmentGone
        gone_error("Assessment not for issue")
      when Helper::RrnHelper::RrnNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment id is not valid",
        )
      when UseCase::FetchDecSummary::AssessmentNotDec
        error_response(403, "NOT_A_DEC", "Assessment is not a DEC")
      else
        server_error(e)
      end
    end
  end
end
