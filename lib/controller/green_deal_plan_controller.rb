# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    SCHEMA = {
      type: "object",
      required: %w[
        greenDealPlanId
        startDate
        endDate
        providerDetails
        interest
        chargeUplift
        ccaRegulated
        structureChanged
        measuresRemoved
        measures
        charges
        savings
      ],
      properties: {
        greenDealPlanId: {
          type: "string",
          pattern: Helper::RegexHelper::GREEN_DEAL_PLAN_ID,
        },
        startDate: {
          type: "string",
          format: "iso-date",
        },
        endDate: {
          type: "string",
          format: "iso-date",
        },
        providerDetails: {
          type: "object",
          required: %w[name],
          properties: {
            name: {
              type: "string",
            },
            telephone: {
              type: "string",
            },
            email: {
              type: "string",
            },
          },
        },
        interest: {
          type: "object",
          required: %w[rate fixed],
          properties: {
            rate: {
              type: "number",
            },
            fixed: {
              type: "boolean",
            },
          },
        },
        chargeUplift: {
          type: "object",
          required: %w[amount],
          properties: {
            amount: {
              type: "number",
            },
            date: {
              type: "string",
              format: "iso-date",
            },
          },
        },
        ccaRegulated: {
          type: "boolean",
        },
        structureChanged: {
          type: "boolean",
        },
        measuresRemoved: {
          type: "boolean",
        },
        measures: {
          type: "array",
          items: {
            type: "object",
            required: %w[product],
            properties: {
              sequence: {
                type: "integer",
              },
              measureType: {
                type: "string",
              },
              product: {
                type: "string",
              },
              repaidDate: {
                type: "string",
                format: "iso-date",
              },
            },
          },
        },
        charges: {
          type: "array",
          items: {
            type: "object",
            required: %w[startDate endDate dailyCharge],
            properties: {
              sequence: {
                type: "integer",
              },
              startDate: {
                type: "string",
                format: "iso-date",
              },
              endDate: {
                type: "string",
                format: "iso-date",
              },
              dailyCharge: {
                type: "number",
              },
            },
          },
        },
        savings: {
          type: "array",
          items: {
            type: "object",
            required: %w[fuelCode fuelSaving standingChargeFraction],
            properties: {
              sequence: {
                type: "integer",
              },
              fuelCode: {
                type: "string",
              },
              fuelSaving: {
                type: "number",
              },
              standingChargeFraction: {
                type: "number",
              },
            },
          },
        },
      },
    }.freeze

    PATCH_SCHEMA = {
      type: "object",
      required: %w[
        greenDealPlanId
        endDate
        charges
      ],
      properties: {
        greenDealPlanId: {
          type: "string",
          pattern: Helper::RegexHelper::GREEN_DEAL_PLAN_ID,
        },
        endDate: {
          type: "string",
          format: "iso-date",
        },
        charges: {
          type: "array",
          items: {
            type: "object",
            required: %w[startDate endDate dailyCharge],
            properties: {
              sequence: {
                type: "integer",
              },
              startDate: {
                type: "string",
                format: "iso-date",
              },
              endDate: {
                type: "string",
                format: "iso-date",
              },
              dailyCharge: {
                type: "number",
              },
            },
          },
        },
      },
    }.freeze

    patch "/api/greendeal/disclosure/plans/:plan_id",
          auth_token_has_all: %w[greendeal:charge-updates] do
      updates = request_body(PATCH_SCHEMA)
      plan_id = params[:plan_id]

      if updates[:green_deal_plan_id] != plan_id
        raise UseCase::UpdateGreenDealPlan::PlanIdMismatchException
      end

      RequestModule.relevant_request_headers = relevant_request_headers(request)

      ApiFactory.patch_green_deal_plan_use_case.execute(json: updates)

      json_api_response code: 204
    rescue StandardError => e
      case e
      when UseCase::PatchGreenDealPlan::NotFoundException
        not_found_error "Green Deal Plan not found"
      when Boundary::Json::ValidationError
        error_response 400, "INVALID_REQUEST", e.message
      when Boundary::Json::Error
        error_response 400, "INVALID_REQUEST", e.message
      when UseCase::UpdateGreenDealPlan::PlanIdMismatchException
        error_response 409,
                       "INVALID_REQUEST",
                       "Green Deal Plan ID does not match"
      else
        server_error e
      end
    end

    post "/api/greendeal/disclosure/assessments/:assessment_id/plans",
         auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      plan = request_body SCHEMA

      RequestModule.relevant_request_headers = relevant_request_headers(request)

      results = ApiFactory.add_green_deal_plan_use_case.execute(assessment_id, plan)

      json_api_response code: 201, data: results.to_hash
    rescue StandardError => e
      case e
      when UseCase::AddGreenDealPlan::NotFoundException
        not_found_error "Assessment not found"
      when UseCase::AddGreenDealPlan::AssessmentGoneException
        gone_error "Assessment not for issue"
      when UseCase::AddGreenDealPlan::AssessmentExpiredException
        gone_error "Assessment has expired"
      when UseCase::AddGreenDealPlan::InvalidTypeException
        error_response 400, "INVALID_REQUEST", "Assessment type is not RdSAP"
      when UseCase::AddGreenDealPlan::DuplicateException
        error_response 409,
                       "INVALID_REQUEST",
                       "Green Deal Plan ID already exists"
      when Boundary::Json::Error
        error_response 400, "INVALID_REQUEST", e.message
      when UseCase::AddGreenDealPlan::InvalidFuelCode
        error_response 400, "INVALID_REQUEST", e.message
      else
        server_error e
      end
    end

    put "/api/greendeal/disclosure/plans/:plan_id",
        auth_token_has_all: %w[greendeal:plans] do
      plan_id = params[:plan_id]
      green_deal_plan = request_body SCHEMA

      RequestModule.relevant_request_headers = relevant_request_headers(request)

      result = ApiFactory.update_green_deal_plan_use_case.execute(plan_id, green_deal_plan)

      json_api_response code: 200, data: result.to_hash
    rescue StandardError => e
      case e
      when UseCase::UpdateGreenDealPlan::NotFoundException
        not_found_error "Green Deal Plan not found"
      when UseCase::UpdateGreenDealPlan::PlanIdMismatchException
        error_response 409,
                       "INVALID_REQUEST",
                       "Green Deal Plan ID does not match"
      when Boundary::Json::Error
        error_response 400, "INVALID_REQUEST", e.message
      when UseCase::UpdateGreenDealPlan::InvalidFuelCode
        error_response 400, "INVALID_REQUEST", e.message
      else
        server_error e
      end
    end

    get "/api/greendeal/rhi/assessments/:assessment_id/latest",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      results = UseCase::FetchRenewableHeatIncentive.new.execute assessment_id

      json_api_response code: 200, data: { assessment: results.to_hash }
    rescue StandardError => e
      case e
      when UseCase::FetchRenewableHeatIncentive::NotFoundException
        not_found_error("Assessment not found")
      when UseCase::FetchRenewableHeatIncentive::AssessmentGone
        gone_error("Assessment not for issue")
      when UseCase::AssessmentSummary::Fetch::AssessmentGone
        gone_error("Assessment not for issue")
      else
        server_error(e)
      end
    end

    get "/api/greendeal/assessments/:assessment_id/xml",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]

      content_type :xml
      body UseCase::FetchRedactedAssessment.new.execute(assessment_id)
    rescue StandardError => e
      case e
      when UseCase::FetchRedactedAssessment::NotAnRdsap
        forbidden("ASSESSMENT_NOT_RDSAP", "Assessment is not an RdSAP")
      when UseCase::FetchRedactedAssessment::NotFoundException
        not_found_error("Assessment not found")
      when UseCase::FetchRedactedAssessment::AssessmentGone
        gone_error("Assessment not for issue")
      when Helper::RrnHelper::RrnNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment id is not valid",
        )
      else
        server_error(e)
      end
    end

    get "/api/greendeal/assessments/:assessment_id",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      result = UseCase::FetchGreenDealAssessment.new.execute(assessment_id)

      json_api_response code: 200, data: { assessment: result }
    rescue StandardError => e
      case e
      when UseCase::FetchGreenDealAssessment::NotFoundException
        not_found_error("Assessment not found")
      when Helper::RrnHelper::RrnNotValid
        error_response 400,
                       "INVALID_REQUEST",
                       "The requested assessment ID is not valid"
      when UseCase::FetchGreenDealAssessment::AssessmentGone
        gone_error("Assessment not for issue")
      when UseCase::FetchGreenDealAssessment::InvalidAssessmentTypeException
        forbidden("UNAUTHORISED", "Assessment is not an RdSAP/SAP")
      else
        server_error(e)
      end
    end

    delete "/api/greendeal/disclosure/plans/:plan_id",
           auth_token_has_all: %w[greendeal:plans] do
      plan_id = params[:plan_id]

      RequestModule.relevant_request_headers = relevant_request_headers(request)

      result = ApiFactory.delete_green_deal_plan_use_case.execute(plan_id)

      json_api_response code: 204, data: result.to_hash
    rescue StandardError => e
      case e
      when UseCase::DeleteGreenDealPlan::NotFoundException
        not_found_error("Green Deal plan ID can not be found")
      else
        server_error e
      end
    end
  end
end
