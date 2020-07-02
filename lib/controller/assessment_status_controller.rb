# frozen_string_literal: true

module Controller
  class AssessmentStatusController < Controller::BaseController
    POST_SCHEMA = {
      type: "object",
      required: %w[status],
      properties: {
        status: { type: "string", enum: %w[CANCELLED NOT_FOR_ISSUE] },
      },
    }.freeze

    post "/api/assessments/:assessment_id/status",
         jwt_auth: %w[assessment:lodge] do
      assessment_id = params[:assessment_id]
      assessment_body = request_body(POST_SCHEMA)

      UseCase::UpdateAssessmentStatus.new.execute(
        assessment_id,
        assessment_body[:status],
        env[:jwt_auth].supplemental("scheme_ids"),
      )

      json_api_response(code: 200, data: { "status": assessment_body[:status] })
    rescue StandardError => e
      case e
      when UseCase::UpdateAssessmentStatus::AssessmentNotLodgedByScheme
        error_response(403, "NOT_ALLOWED", e.message)
      when UseCase::UpdateAssessmentStatus::AssessmentAlreadyCancelled
        gone_error("Assessment has already been cancelled")
      when UseCase::UpdateAssessmentStatus::AssessmentNotFound
        not_found_error("Assessment not found")
      else
        server_error(e.message)
      end
    end
  end
end
