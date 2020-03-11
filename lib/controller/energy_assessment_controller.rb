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
        heatDemand
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
        schemeAssessorId: { type: 'string' },
        heatDemand: { type: 'object', required: %w[currentSpaceHeatingDemand], properties: {
            currentSpaceHeatingDemand: {
                type: 'integer'
            }
        }}
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

      new_assessment = Domain::DomesticEnergyAssessment.new(
          assessment_body[:date_of_assessment],
          assessment_body[:date_registered],
          assessment_body[:dwelling_type],
          assessment_body[:type_of_assessment],
          assessment_body[:total_floor_area],
          assessment_id,
          assessment_body[:scheme_assessor_id],
          assessment_body[:address_summary],
          assessment_body[:current_energy_efficiency_rating],
          assessment_body[:potential_energy_efficiency_rating],
          assessment_body[:postcode],
          assessment_body[:date_of_expiry],
          assessment_body[:address_line1],
          assessment_body[:address_line2],
          assessment_body[:address_line3],
          assessment_body[:address_line4],
          assessment_body[:town]
          )

      result = migrate_epc.execute_with_object(new_assessment)

      @events.event(
        :domestic_energy_assessment_migrated,
        params[:assessment_id]
      )
      json_response(200, result.to_hash)
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
