# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    get "/api/greendeal/rhi/assessments/:assessment_id/latest",
        jwt_auth: %w[greendeal:assessment:fetch] do
      assessment_id = params[:assessment_id]
      results =
        @container.get_object(:fetch_renewable_heat_incentive_use_case).execute(
          assessment_id,
        )
      p results
      json_api_response(code: 200, data: results.map(&:to_hash))
    rescue StandardError => e
      case e
      when UseCase::FetchRenewableHeatIncentive::NotFoundException
        not_found_error("Assessment not found")
      else
        server_error(e)
      end
    end
  end
end
