# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    post "/api/greendeal/disclosure/assessments/:assessment_id/plans",
         jwt_auth: %w[greendeal:plans] do
      json_api_response code: 201
    end

    get "/api/greendeal/rhi/assessments/:assessment_id/latest",
        jwt_auth: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]

      results =
        @container.get_object(
          :fetch_renewable_heat_incentive_use_case,
        ).execute assessment_id

      json_api_response code: 200, data: { assessment: results.to_hash }
    rescue StandardError => e
      case e
      when UseCase::FetchRenewableHeatIncentive::NotFoundException
        not_found_error("Assessment not found")
      when UseCase::FetchRenewableHeatIncentive::AssessmentGone
        gone_error("Assessment not for issue")
      else
        server_error(e)
      end
    end
  end
end
