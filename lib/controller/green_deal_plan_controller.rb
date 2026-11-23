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

      ApiFactory.patch_green_deal_plan_use_case.execute(json: updates)

      json_api_response code: 204
    rescue UseCase::PatchGreenDealPlan::NotFoundException
      not_found_error "Green Deal Plan not found"
    rescue Boundary::Json::ValidationError => e
      error_response 400, "INVALID_REQUEST", e.message
    rescue Boundary::Json::Error => e
      error_response 400, "INVALID_REQUEST", e.message
    rescue UseCase::UpdateGreenDealPlan::PlanIdMismatchException
      error_response 409, "INVALID_REQUEST", "Green Deal Plan ID does not match"
    end

    post "/api/greendeal/disclosure/assessments/:assessment_id/plans",
         auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      plan = request_body SCHEMA

      results = ApiFactory.add_green_deal_plan_use_case.execute(assessment_id, plan)

      json_api_response code: 201, data: results.to_hash
    rescue UseCase::AddGreenDealPlan::NotFoundException
      not_found_error "Assessment not found"
    rescue UseCase::AddGreenDealPlan::AssessmentGoneException
      gone_error "Assessment not for issue"
    rescue UseCase::AddGreenDealPlan::AssessmentExpiredException
      gone_error "Assessment has expired"
    rescue UseCase::AddGreenDealPlan::InvalidTypeException
      error_response 400, "INVALID_REQUEST", "Assessment type is not RdSAP"
    rescue UseCase::AddGreenDealPlan::DuplicateException
      error_response 409, "INVALID_REQUEST", "Green Deal Plan ID already exists"
    rescue Boundary::Json::Error => e
      error_response 400, "INVALID_REQUEST", e.message
    rescue UseCase::AddGreenDealPlan::InvalidFuelCode => e
      error_response 400, "INVALID_REQUEST", e.message
    end

    put "/api/greendeal/disclosure/plans/:plan_id",
        auth_token_has_all: %w[greendeal:plans] do
      plan_id = params[:plan_id]
      green_deal_plan = request_body SCHEMA

      result = ApiFactory.update_green_deal_plan_use_case.execute(plan_id, green_deal_plan)

      json_api_response code: 200, data: result.to_hash
    rescue UseCase::UpdateGreenDealPlan::NotFoundException
      not_found_error "Green Deal Plan not found"
    rescue UseCase::UpdateGreenDealPlan::PlanIdMismatchException
      error_response 409, "INVALID_REQUEST", "Green Deal Plan ID does not match"
    rescue Boundary::Json::Error => e
      error_response 400, "INVALID_REQUEST", e.message
    rescue UseCase::UpdateGreenDealPlan::InvalidFuelCode => e
      error_response 400, "INVALID_REQUEST", e.message
    end

    get "/api/greendeal/rhi/assessments/:assessment_id/latest",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      results = UseCase::FetchRenewableHeatIncentive.new.execute assessment_id

      json_api_response code: 200, data: { assessment: results.to_hash }
    rescue UseCase::FetchRenewableHeatIncentive::NotFoundException
      not_found_error("Assessment not found")
    rescue UseCase::FetchRenewableHeatIncentive::AssessmentGone
      gone_error("Assessment not for issue")
    rescue UseCase::AssessmentSummary::Fetch::AssessmentGone
      gone_error("Assessment not for issue")
    end

    get "/api/greendeal/assessments/:assessment_id/xml",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]

      content_type :xml
      body UseCase::FetchRedactedAssessment.new.execute(assessment_id)
    rescue UseCase::FetchRedactedAssessment::NotAnRdsap
      forbidden("ASSESSMENT_NOT_RDSAP", "Assessment is not an RdSAP")
    rescue UseCase::FetchRedactedAssessment::NotFoundException
      not_found_error("Assessment not found")
    rescue UseCase::FetchRedactedAssessment::AssessmentGone
      gone_error("Assessment not for issue")
    rescue Helper::RrnHelper::RrnNotValid
      error_response 400, "INVALID_REQUEST", "The requested assessment id is not valid"
    end

    get "/api/greendeal/assessments/:assessment_id",
        auth_token_has_all: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      result = UseCase::FetchGreenDealAssessment.new.execute(assessment_id)

      json_api_response code: 200, data: { assessment: result }
    rescue UseCase::FetchGreenDealAssessment::NotFoundException
      not_found_error("Assessment not found")
    rescue Helper::RrnHelper::RrnNotValid
      error_response 400, "INVALID_REQUEST", "The requested assessment ID is not valid"
    rescue UseCase::FetchGreenDealAssessment::AssessmentGone
      gone_error("Assessment not for issue")
    rescue UseCase::FetchGreenDealAssessment::InvalidAssessmentTypeException
      forbidden "UNAUTHORISED", "Assessment is not an RdSAP/SAP"
    end

    delete "/api/greendeal/disclosure/plans/:plan_id",
           auth_token_has_all: %w[greendeal:plans] do
      plan_id = params[:plan_id]

      result = ApiFactory.delete_green_deal_plan_use_case.execute(plan_id)

      json_api_response code: 204, data: result.to_hash
    rescue UseCase::DeleteGreenDealPlan::NotFoundException
      not_found_error("Green Deal plan ID can not be found")
    end
  end
end
