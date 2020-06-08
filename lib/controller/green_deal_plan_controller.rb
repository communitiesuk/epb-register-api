# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    get "/api/greendeal/assessments/:assessment_id",
        jwt_auth: %w[greendeal:assessment:fetch] do
      assessment_id = params[:assessment_id]
      result
      @container.get_object(:fetch_assessment_use_case).execute(assessment_id)
      json_api_response(code: 200, data: result)
    rescue StandardError => e
      case e
      when UseCase::FetchAssessment::NotFoundException
        not_found_error("Assessment not found")
      else
        server_error(e)
      end
    end
  end
end
