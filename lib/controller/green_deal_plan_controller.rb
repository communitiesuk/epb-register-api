# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    post "/api/greendeal/disclosure/assessments/:assessment_id/plans",
         jwt_auth: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      UseCase::AddGreenDealPlan.new.execute assessment_id

      json_api_response code: 201
    rescue StandardError => e
      case e
      when UseCase::AddGreenDealPlan::NotFoundException
        not_found_error "Assessment not found"
      when UseCase::AddGreenDealPlan::AssessmentGoneException
        gone_error "Assessment not for issue"
      when UseCase::AddGreenDealPlan::InvalidTypeException
        error_response 400, "INVALID_REQUEST", "Assessment type is not RdSAP"
      else
        server_error e
      end
    end

    get "/api/greendeal/rhi/assessments/:assessment_id/latest",
        jwt_auth: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      results = UseCase::FetchRenewableHeatIncentive.new.execute assessment_id

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
