module Controller
  class EnergyAssessmentController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[
        addressSummary
        dateOfAssessment
        dateRegistered
        totalFloorArea
        dwellingType
        typeOfAssessment
        currentEnergyEfficiencyRating
        potentialEnergyEfficiencyRating
        schemeAssessorId
      ],
      properties: {
        addressSummary: { type: 'string' },
        dateOfAssessment: { type: 'string', format: 'iso-date' },
        dateRegistered: { type: 'string', format: 'iso-date' },
        totalFloorArea: { type: 'integer' },
        dwellingType: { type: 'string' },
        typeOfAssessment: { type: 'string', enum: %w[SAP RdSAP] },
        currentEnergyEfficiencyRating: { type: 'integer' },
        potentialEnergyEfficiencyRating: { type: 'integer' },
        schemeAssessorId: { type: 'string' }
      }
    }

    get '/api/assessments/domestic-energy-performance/search', jwt_auth: [] do
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

    get '/api/assessments/domestic-energy-performance/:assessment_id',
        jwt_auth: [] do
      assessment_id = params[:assessment_id]
      result =
        @container.get_object(:fetch_domestic_energy_assessment_use_case)
          .execute(assessment_id)
      json_response(200, result)
    rescue Exception => e
      case e
      when UseCase::FetchDomesticEnergyAssessment::NotFoundException
        not_found_error('Assessment not found')
      else
        server_error(e)
      end
    end

    put '/api/assessments/domestic-energy-performance/:assessment_id',
        jwt_auth: [] do
      assessment_id = params[:assessment_id]
      migrate_epc =
        @container.get_object(:migrate_domestic_energy_assessment_use_case)
      assessment_body = request_body(PUT_SCHEMA)
      result = migrate_epc.execute(assessment_id, assessment_body)

      @events.event(
        :domestic_energy_assessment_migrated,
        params[:assessment_id]
      )
      json_response(200, result)
    rescue Exception => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, 'INVALID_REQUEST', e.message)
      when Gateway::DomesticEnergyAssessmentsGateway::InvalidCurrentEnergyRatingException
        error_response(
          422,
          'INVALID_REQUEST',
          'Current energy efficiency rating is not an integer between 1 and 100'
        )
      when Gateway::DomesticEnergyAssessmentsGateway::InvalidPotentialEnergyRatingException
        error_response(
          422,
          'INVALID_REQUEST',
          'Potential energy efficiency rating is not an integer between 1 and 100'
        )
      else
        server_error(e)
      end
    end
  end
end
