# frozen_string_literal: true

module Controller
  class EnergyAssessmentController < Controller::BaseController
    PUT_SCHEMA = {
      type: "object",
      required: %w[
        addressLine1
        town
        postcode
        dateOfAssessment
        dateRegistered
        dateOfExpiry
        totalFloorArea
        dwellingType
        typeOfAssessment
        currentEnergyEfficiencyRating
        potentialEnergyEfficiencyRating
        currentCarbonEmission
        potentialCarbonEmission
        optOut
        schemeAssessorId
        heatDemand
        recommendedImprovements
      ],
      properties: {
        addressLine1: { type: "string" },
        addressLine2: { type: %w[string null] },
        addressLine3: { type: %w[string null] },
        addressLine4: { type: %w[string null] },
        town: { type: "string" },
        postcode: { type: "string" },
        dateOfAssessment: { type: "string", format: "iso-date" },
        dateRegistered: { type: "string", format: "iso-date" },
        dateOfExpiry: { type: "string", format: "iso-date" },
        totalFloorArea: { type: "number" },
        dwellingType: { type: "string" },
        typeOfAssessment: { type: "string", enum: %w[SAP RdSAP CEPC] },
        currentEnergyEfficiencyRating: { type: "integer" },
        potentialEnergyEfficiencyRating: { type: "integer" },
        currentCarbonEmission: { type: "number" },
        potentialCarbonEmission: { type: "number" },
        optOut: { type: "boolean" },
        schemeAssessorId: { type: "string" },
        heatDemand: {
          type: "object",
          required: %w[currentSpaceHeatingDemand currentWaterHeatingDemand],
          properties: {
            currentSpaceHeatingDemand: { type: "number" },
            currentWaterHeatingDemand: { type: "number" },
            impactOfLoftInsulation: { type: "integer" },
            impactOfCavityInsulation: { type: "integer" },
            impactOfSolidWallInsulation: { type: "integer" },
          },
        },
        recommendedImprovements: {
          type: "array",
          items: {
            anyOf: [
              {
                type: "object",
                required: %w[sequence improvementCode typicalSaving],
                properties: {
                  sequence: { type: "integer", format: "positive-int" },
                  improvementCode: {
                    type: %w[string], enum: [*"1".."63"].freeze
                  },
                  indicativeCost: { type: %w[string null] },
                  typicalSaving: { type: "number", format: "positive-int" },
                  improvementCategory: { type: "string" },
                  improvementType: { type: "string" },
                  improvementTitle: { type: "null" },
                  improvementDescription: { type: "null" },
                  energyPerformanceRatingImprovement: { type: "integer" },
                  environmentalImpactRatingImprovement: { type: "integer" },
                  greenDealCategoryCode: { type: "string" },
                },
              },
              {
                type: "object",
                required: %w[
                  sequence
                  improvementTitle
                  improvementDescription
                  typicalSaving
                ],
                properties: {
                  sequence: { type: "integer", format: "positive-int" },
                  improvementCode: { type: "null" },
                  indicativeCost: { type: %w[string null] },
                  typicalSaving: { type: "number", format: "positive-int" },
                  improvementCategory: { type: "string" },
                  improvementType: { type: "string" },
                  improvementTitle: { type: "string" },
                  improvementDescription: { type: "string" },
                  energyPerformanceRatingImprovement: { type: "integer" },
                  environmentalImpactRatingImprovement: { type: "integer" },
                  greenDealCategoryCode: { type: "string" },
                },
              },
            ],
          },
        },
        propertySummary: {
          type: "array",
          items: {
            anyOf: [
              {
                type: "object",
                required: %w[
                  name
                  description
                  energyEfficiencyRating
                  environmentalEfficiencyRating
                ],
                properties: {
                  name: { type: "string" },
                  description: { type: "string" },
                  energyEfficiencyRating: {
                    type: "number", format: "positive-int"
                  },
                  environmentalEfficiencyRating: {
                    type: "number", format: "positive-int"
                  },
                },
              },
            ],
          },
        },
        oneOf: [
          {
            relatedPartyDisclosureNumber: { type: "integer" },
            relatedPartyDisclosureText: { type: "null" },
          },
          {
            relatedPartyDisclosureNumber: { type: "null" },
            relatedPartyDisclosureText: { type: "string" },
          },
        ],
      },
    }.freeze

    get "/api/assessments/domestic-epc/search",
        jwt_auth: %w[assessment:search] do
      result =
          if params.key?(:postcode)
            @container.get_object(:find_assessments_by_postcode_use_case).execute(
                params[:postcode],
                )
          elsif params.key?(:assessment_id)
            @container.get_object(:find_assessments_by_assessment_id_use_case)
                .execute(params[:assessment_id])
          else
            @container.get_object(
                :find_assessments_by_street_name_and_town_use_case,
                )
                .execute(params[:street_name], params[:town])
          end

      json_api_response(code: 200, data: result, burrow_key: :assessments)
    rescue StandardError => e
      case e
      when UseCase::FindAssessmentsByStreetNameAndTown::ParameterMissing
        error_response(
            400,
            "MALFORMED_REQUEST",
            "Required query params missing",
            )
      else
        server_error(e.message)
      end
    end

    get "/api/assessments/search",
        jwt_auth: %w[assessment:search] do
      result =
          if params.key?(:postcode)
            @container.get_object(:find_assessments_by_postcode_use_case).execute(
                params[:postcode],
                )
          elsif params.key?(:assessment_id)
            @container.get_object(:find_assessments_by_assessment_id_use_case)
                .execute(params[:assessment_id])
          else
            @container.get_object(
                :find_assessments_by_street_name_and_town_use_case,
                )
                .execute(params[:street_name], params[:town])
          end

      json_api_response(code: 200, data: result, burrow_key: :assessments)
    rescue StandardError => e
      case e
      when UseCase::FindAssessmentsByStreetNameAndTown::ParameterMissing
        error_response(
            400,
            "MALFORMED_REQUEST",
            "Required query params missing",
            )
      else
        server_error(e.message)
      end
    end

    post "/api/assessments", jwt_auth: %w[assessment:lodge] do
      do_lodge
    end

    get "/api/assessments/:assessment_id", jwt_auth: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]
      result =
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

    put "/api/assessments/domestic-epc/:assessment_id",
        jwt_auth: %w[migrate:assessment] do
      assessment_id = params[:assessment_id]
      migrate_epc = @container.get_object(:migrate_assessment_use_case)
      assessment_body = request_body(PUT_SCHEMA)
      result = migrate_epc.execute(assessment_id, assessment_body)

      @events.event(
        :domestic_energy_assessment_migrated,
        params[:assessment_id],
      )
      json_api_response(code: 200, data: result.to_hash)
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, "INVALID_REQUEST", e.message)
      when UseCase::MigrateAssessment::AssessmentRuleException
        error_response(422, "ASSESSMENT_RULE_VIOLATION", e.message)
      when ArgumentError
        error_response(422, "INVALID_REQUEST", e.message)
      else
        server_error(e)
      end
    end

    def do_lodge
      correlation_id = rand
      logit_char_limit = 50_000

      sanitized_body =
        Helper::SanitizeXmlHelper.new.sanitize(request.body.read.to_s)

      @events.event(
        false,
        {
          event_type: :lodgement_attempt,
          correlation_id: correlation_id,
          request_body: sanitized_body.slice(0..logit_char_limit),
          request_headers: headers,
          request_body_truncated: sanitized_body.length > logit_char_limit,
        },
        true,
      )

      sup = env[:jwt_auth].supplemental("scheme_ids")
      validate_and_lodge_assessment =
        @container.get_object(:validate_and_lodge_assessment_use_case)

      xml = sanitized_body
      content_type = request.env["CONTENT_TYPE"].split("+")[1]
      scheme_ids = sup

      results =
        validate_and_lodge_assessment.execute(xml, content_type, scheme_ids)

      results.each do |result|
        @events.event(
          false,
          {
            event_type: :lodgement_successful,
            correlation_id: correlation_id,
            assessment_id: result.assessment_id,
          },
          true,
        )
      end

      json_api_response(
        code: 201, data: (results.size > 1 ? results : results.first),
      )
    rescue StandardError => e
      @events.event(
        false,
        {
          event_type: :lodgement_failed,
          correlation_id: correlation_id,
          error_message: e.to_s,
        },
        true,
      )

      case e
      when UseCase::ValidateAssessment::InvalidXmlException
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException
        error_response(400, "INVALID_REQUEST", "Schema is not supported.")
      when UseCase::CheckAssessorBelongsToScheme::AssessorNotFoundException
        error_response(400, "INVALID_REQUEST", "Assessor is not registered.")
      when UseCase::ValidateAndLodgeAssessment::SchemaNotDefined
        error_response(
          400,
          "INVALID_REQUEST",
          'Schema is not defined. Set content-type on the request to "application/xml+RdSAP-Schema-19.0" for example.',
        )
      when UseCase::ValidateAndLodgeAssessment::UnauthorisedToLodgeAsThisSchemeException
        error_response(
          403,
          "UNAUTHORISED",
          "Not authorised to lodge reports as this scheme",
        )
      when UseCase::LodgeAssessment::InactiveAssessorException
        error_response(400, "INVALID_REQUEST", "Assessor is not active.")
      when UseCase::LodgeAssessment::DuplicateAssessmentIdException
        error_response(409, "INVALID_REQUEST", "Assessment ID already exists.")
      when REXML::ParseException
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::LodgeAssessment::AssessmentRuleException
        error_response(422, "ASSESSMENT_RULE_VIOLATION", e.message)
      else
        server_error(e)
      end
    end
  end
end
