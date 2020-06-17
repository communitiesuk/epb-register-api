# frozen_string_literal: true

module Controller
  class AssessmentStatusController < Controller::BaseController
    POST_SCHEMA = {
      type: "object",
      required: %w[status],
      properties: {
        status: { type: "string", enum: %w[CANCELLED NOT_FOR_ISSUE CEPC] },
      },
    }.freeze

    post "/api/assessments/:assessment_id/status",
         jwt_auth: %w[assessment:lodge] do
      assessment_id = params[:assessment_id]
      assessment_body = request_body(POST_SCHEMA)

      @container.get_object(:update_assessments_status_use_case).execute(
        assessment_id,
        assessment_body[:status],
      )

      json_api_response(code: 200, data: { "status": assessment_body[:status] })
    end
  end
end
