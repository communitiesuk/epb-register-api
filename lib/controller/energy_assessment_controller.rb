module Controller
  class EnergyAssessmentController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[
        addressSummary
        addressLine1
        addressLine2
        addressLine3
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
        addressLine2: { type: 'string' },
        addressLine3: { type: 'string' },
        addressLine4: { type: 'string' },
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
            required: %w[sequence],
            properties: {
              sequence: { type: 'integer', format: 'positive-int' },
              improvementCode: { type: 'string' },
              indicativeCost: { type: 'string' },
              typicalSaving: { type: 'number', format: 'positive-int' },
              improvementCategory: { type: 'string' },
              improvementType: { type: 'string' },
              energyPerformanceRating: { type: 'string' },
              environmentalImpactRating: { type: 'string' },
              greenDealCategoryCode: { type: 'string' }
            }
          }
        }
      }
    }

    get '/api/assessments/domestic-epc/search',
        jwt_auth: %w[assessment:search] do
      if params.has_key?(:postcode)
        result =
          @container.get_object(:find_assessments_by_postcode_use_case).execute(
            params[:postcode]
          )
      elsif params.has_key?(:assessment_id)
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
    rescue Exception => e
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
    rescue Exception => e
      case e
      when UseCase::FetchDomesticEnergyAssessment::NotFoundException
        not_found_error('Assessment not found')
      else
        server_error(e)
      end
    end

    post '/api/assessments/:assessment_id', jwt_auth: %w[assessment:lodge] do
      schema =
        'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd'

      assessment_body = xml_request_body(schema)

      lodge_assessment = @container.get_object(:lodge_assessment_use_case)

      result =
        lodge_assessment.execute(
          assessment_body,
          params[:assessment_id],
          request.env['CONTENT_TYPE']
        )

      json_api_response(201, result.to_hash)
    rescue StandardError => e
      case e
      when Helper::InvalidXml
        error_response(400, 'INVALID_REQUEST', e.message)
      when UseCase::FetchAssessor::AssessorNotFoundException
        error_response(400, 'IVALID_REQUEST', 'Assessor is not registered.')
      when UseCase::LodgeAssessment::InactiveAssessorException
        error_response(400, 'INVALID_REQUEST', 'Assessor is not active.')
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
    rescue Exception => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, 'INVALID_REQUEST', e.message)
      when ArgumentError
        error_response(422, 'INVALID_REQUEST', e.message)
      else
        server_error(e)
      end
    end
  end
end
