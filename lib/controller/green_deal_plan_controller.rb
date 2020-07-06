# frozen_string_literal: true

module Controller
  class GreenDealPlanController < Controller::BaseController
    POST_SCHEMA = {
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
        greenDealPlanId: { type: "string" },
        startDate: { type: "string", format: "iso-date" },
        endDate: { type: "string", format: "iso-date" },
        providerDetails: {
          type: "object",
          required: %w[name telephone email],
          properties: {
            name: { type: "string" },
            telephone: { type: "string" },
            email: { type: "string" },
          },
        },
        interest: {
          type: "object",
          required: %w[rate fixed],
          properties: { rate: { type: "number" }, fixed: { type: "boolean" } },
        },
        chargeUplift: {
          type: "object",
          properties: {
            amount: { type: "number" },
            date: { type: "string", format: "iso-date" },
          },
        },
        ccaRegulated: { type: "boolean" },
        structureChanged: { type: "boolean" },
        measuresRemoved: { type: "boolean" },
        measures: {
          type: "array",
          properties: {
            sequence: { type: "integer" },
            measureType: { type: "string" },
            product: { type: "string" },
            repaidDate: { type: "string", format: "iso-date" },
          },
        },
        charges: {
          type: "array",
          properties: {
            sequence: { type: "integer" },
            startDate: { type: "string", format: "iso-date" },
            endDate: { type: "string", format: "iso-date" },
            dailyCharge: { type: "number" },
          },
        },
        savings: {
          type: "array",
          properties: {
            sequence: { type: "integer" },
            fuelCode: { type: "string" },
            fuelSaving: { type: "integer" },
            standingChargeFraction: { type: "number" },
          },
        },
      },
    }.freeze

    post "/api/greendeal/disclosure/assessments/:assessment_id/plans",
         jwt_auth: %w[greendeal:plans] do
      assessment_id = params[:assessment_id]
      plan = request_body POST_SCHEMA

      results = UseCase::AddGreenDealPlan.new.execute assessment_id, plan

      json_api_response code: 201, data: results.to_hash
    rescue StandardError => e
      case e
      when UseCase::AddGreenDealPlan::NotFoundException
        not_found_error "Assessment not found"
      when UseCase::AddGreenDealPlan::AssessmentGoneException
        gone_error "Assessment not for issue"
      when UseCase::AddGreenDealPlan::InvalidTypeException
        error_response 400, "INVALID_REQUEST", "Assessment type is not RdSAP"
      when UseCase::AddGreenDealPlan::DuplicateException
        error_response(
          409,
          "INVALID_REQUEST",
          "Green Deal Plan ID already exists",
        )
      when JSON::Schema::ValidationError
        error_response(422, "INVALID_REQUEST", e.message)
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
