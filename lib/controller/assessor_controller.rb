module Controller
  class AssessorController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[firstName lastName dateOfBirth],
      properties: {
        firstName: { type: 'string' },
        lastName: { type: 'string' },
        middleNames: { type: 'string' },
        dateOfBirth: { type: 'string', format: 'iso-date' },
        contactDetails: {
          type: 'object',
          properties: {
            telephoneNumber: { type: 'string', format: 'telephone' },
            email: { type: 'string', format: 'email' }
          }
        }
      }
    }

    get '/api/schemes/:scheme_id/assessors/:scheme_assessor_id' do
      scheme_id = params[:scheme_id]
      scheme_assessor_id = params[:scheme_assessor_id]
      result =
        @container.get_object(:fetch_assessor_use_case).execute(
          scheme_id,
          scheme_assessor_id
        )
      json_response(200, result)
    rescue Exception => e
      case e
      when UseCase::FetchAssessor::SchemeNotFoundException
        not_found_error('The requested scheme was not found')
      when UseCase::FetchAssessor::AssessorNotFoundException
        not_found_error('The requested assessor was not found')
      else
        server_error(e.message)
      end
    end

    put '/api/schemes/:scheme_id/assessors/:scheme_assessor_id' do
      scheme_id = params['scheme_id']
      scheme_assessor_id = params['scheme_assessor_id']
      assessor_details = request_body(PUT_SCHEMA)
      create_assessor_response =
        @container.get_object(:add_assessor_use_case).execute(
          scheme_id,
          scheme_assessor_id,
          assessor_details
        )
      if create_assessor_response[:assessor_was_newly_created]
        @events.event(
          :new_assessor_registered,
          create_assessor_response[:assessor][:scheme_assessor_id]
        )
        json_response(201, create_assessor_response[:assessor])
      else
        @events.event(
          :assessor_updated,
          create_assessor_response[:assessor][:scheme_assessor_id]
        )
        json_response(200, create_assessor_response[:assessor])
      end
    rescue Exception => e
      case e
      when UseCase::AddAssessor::SchemeNotFoundException
        not_found_error('The requested scheme was not found')
      when UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
        error_response(
          409,
          'ASSESSOR_ID_ON_ANOTHER_SCHEME',
          'The assessor ID you are trying to update is registered by a different scheme'
        )
      when JSON::ParserError
        error_response(400, 'INVALID_REQUEST', e.message)
      when JSON::Schema::ValidationError
        error_response(422, 'INVALID_REQUEST', e.message)
      else
        server_error(e.message)
      end
    end
  end
end
