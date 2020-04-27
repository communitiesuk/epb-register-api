# frozen_string_literal: true

module Controller
  class EnergyAssessmentController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[
        addressSummary
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
        schemeAssessorId
        heatDemand
        recommendedImprovements
      ],
      properties: {
        addressSummary: { type: 'string' },
        addressLine1: { type: 'string' },
        addressLine2: { type: %w[string null] },
        addressLine3: { type: %w[string null] },
        addressLine4: { type: %w[string null] },
        town: { type: 'string' },
        postcode: { type: 'string' },
        dateOfAssessment: { type: 'string', format: 'iso-date' },
        dateRegistered: { type: 'string', format: 'iso-date' },
        dateOfExpiry: { type: 'string', format: 'iso-date' },
        totalFloorArea: { type: 'number' },
        dwellingType: { type: 'string' },
        typeOfAssessment: { type: 'string', enum: %w[SAP RdSAP] },
        currentEnergyEfficiencyRating: { type: 'integer' },
        potentialEnergyEfficiencyRating: { type: 'integer' },
        schemeAssessorId: { type: 'string' },
        heatDemand: {
          type: 'object',
          required: %w[currentSpaceHeatingDemand currentWaterHeatingDemand],
          properties: {
            currentSpaceHeatingDemand: { type: 'number' },
            currentWaterHeatingDemand: { type: 'number' },
            impactOfLoftInsulation: { type: 'integer' },
            impactOfCavityInsulation: { type: 'integer' },
            impactOfSolidWallInsulation: { type: 'integer' }
          }
        },
        recommendedImprovements: {
          type: 'array',
          items: {
            type: 'object',
            required: %w[sequence improvementCode indicativeCost typicalSaving],
            properties: {
              sequence: { type: 'integer', format: 'positive-int' },
              improvementCode: { type: 'string', enum: [*'1'..'63'].freeze },
              indicativeCost: { type: 'string' },
              typicalSaving: { type: 'number', format: 'positive-int' },
              improvementCategory: { type: 'string' },
              improvementType: { type: 'string' },
              energyPerformanceRatingImprovement: { type: 'integer' },
              environmentalImpactRatingImprovement: { type: 'integer' },
              greenDealCategoryCode: { type: 'string' }
            }
          }
        }
      }
    }.freeze

    get '/api/assessments/domestic-epc/search',
        jwt_auth: %w[assessment:search] do
      if params.key?(:postcode)
        result =
          @container.get_object(:find_assessments_by_postcode_use_case).execute(
            params[:postcode]
          )
      elsif params.key?(:assessment_id)
        result =
          @container.get_object(:find_assessments_by_assessment_id_use_case)
            .execute(params[:assessment_id])
      else
        result =
          @container.get_object(
            :find_assessments_by_street_name_and_town_use_case
          )
            .execute(params[:street_name], params[:town])
      end

      json_response(200, result)
    rescue StandardError => e
      case e
      when UseCase::FindAssessmentsByStreetNameAndTown::ParameterMissing
        error_response(
          400,
          'MALFORMED_REQUEST',
          'Required query params missing'
        )
      else
        server_error(e.message)
      end
    end

    get '/api/assessments/domestic-epc/:assessment_id',
        jwt_auth: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]
      result =
        @container.get_object(:fetch_domestic_energy_assessment_use_case)
          .execute(assessment_id)
      json_api_response(200, result)
    rescue StandardError => e
      case e
      when UseCase::FetchDomesticEnergyAssessment::NotFoundException
        not_found_error('Assessment not found')
      else
        server_error(e)
      end
    end

    post '/api/assessments/:assessment_id', jwt_auth: %w[assessment:lodge] do
      sup = env[:jwt_auth].supplemental('scheme_ids')
      validate_and_lodge_assessment =
        @container.get_object(:validate_and_lodge_assessment_use_case)

      assessment_id = params[:assessment_id]
      xml = request.body.read.to_s
      content_type = request.env['CONTENT_TYPE'].split('+')[1]
      scheme_ids = sup

      result =
        validate_and_lodge_assessment.execute(
          assessment_id,
          xml,
          content_type,
          scheme_ids
        )
      json_api_response(201, result.to_hash)
    rescue StandardError => e
      case e
      when UseCase::ValidateAssessment::InvalidXml
        error_response(400, 'INVALID_REQUEST', e.message)
      when UseCase::ValidateAndLodgeAssessment::SchemaNotSupported
        error_response(400, 'INVALID_REQUEST', 'Schema not supported.')
      when UseCase::CheckAssessorBelongsToScheme::AssessorNotFoundException
        error_response(400, 'IVALID_REQUEST', 'Assessor is not registered.')
      when UseCase::ValidateAndLodgeAssessment::NotAuthorisedToLodgeAsThisScheme
        error_response(
          403,
          'UNAUTHORISED',
          'Not authorised to lodge reports as this scheme'
        )
      when UseCase::LodgeAssessment::AssessmentIdMismatch
        error_response(
          422,
          'INVALID_REQUEST',
          'Assessment ID and RRN in XML does not match.'
        )
      when UseCase::LodgeAssessment::InactiveAssessorException
        error_response(400, 'INVALID_REQUEST', 'Assessor is not active.')
      when UseCase::LodgeAssessment::DuplicateAssessmentIdException
        error_response(409, 'INVALID_REQUEST', 'Assessment ID already exists.')
      when UseCase::LodgeAssessment::AssessmentRuleException
        error_response(422, 'ASSESSMENT_RULE_VIOLATION', e.message)
      else
        server_error(e)
      end
    end

    put '/api/assessments/domestic-epc/:assessment_id',
        jwt_auth: %w[migrate:assessment] do
      assessment_id = params[:assessment_id]
      migrate_epc =
        @container.get_object(:migrate_domestic_energy_assessment_use_case)
      assessment_body = request_body(PUT_SCHEMA)
      result = migrate_epc.execute(assessment_id, assessment_body)

      @events.event(
        :domestic_energy_assessment_migrated,
        params[:assessment_id]
      )
      json_api_response(200, result.to_hash)
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, 'INVALID_REQUEST', e.message)
      when UseCase::MigrateDomesticEnergyAssessment::AssessmentRuleException
        error_response(422, 'ASSESSMENT_RULE_VIOLATION', e.message)
      when ArgumentError
        error_response(422, 'INVALID_REQUEST', e.message)
      else
        server_error(e)
      end
    end

    private

    def scheme_is_authorised_to_lodge(scheme_ids_from_auth, request_body)
      scheme_assessor_id =
        request_body[:RdSAP_Report][:Report_Header][:Energy_Assessor][
          :Identification_Number
        ][
          :Membership_Number
        ]
      use_case =
        @container.get_object(:check_assessor_belongs_to_scheme_use_case)
      use_case.execute(scheme_assessor_id, scheme_ids_from_auth)
    end
  end
end
