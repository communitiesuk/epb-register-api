module Controller
  class AssessorController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[firstName lastName dateOfBirth],
      properties: {
        firstName: { type: 'string' },
        lastName: { type: 'string' },
        middleNames: { type: 'string' },
        dateOfBirth: { type: 'string', format: 'iso-date' }
      }
    }

    get '/api/schemes/:scheme_id/assessors/:scheme_assessor_id' do
      content_type :json
      scheme_id = params[:scheme_id]
      scheme_assessor_id = params[:scheme_assessor_id]
      result =
        @container.get_object(:fetch_assessor_use_case).execute(
          scheme_id,
          scheme_assessor_id
        )
      200
      @json_helper.convert_to_json(result)
    rescue Exception => e
      case e
      when UseCase::FetchAssessor::SchemeNotFoundException
        status 404
        single_error_response('NOT_FOUND', 'The requested scheme was not found')
      when UseCase::FetchAssessor::AssessorNotFoundException
        status 404
        single_error_response(
          'NOT_FOUND',
          'The requested assessor was not found'
        )
      else
        status 500
        single_error_response('SERVER_ERROR', e.message)
      end
    end

    put '/api/schemes/:scheme_id/assessors/:scheme_assessor_id' do
      content_type :json
      scheme_id = params['scheme_id']
      scheme_assessor_id = params['scheme_assessor_id']
      assessor_details =
        @json_helper.convert_to_ruby_hash(request.body.read.to_s, PUT_SCHEMA)
      create_assessor_response =
        @container.get_object(:add_assessor_use_case).execute(
          scheme_id,
          scheme_assessor_id,
          assessor_details
        )
      if create_assessor_response[:assessor_was_newly_created]
        status 201
      else
        status 200
      end
      @json_helper.convert_to_json(create_assessor_response[:assessor])
    rescue Exception => e
      case e
      when UseCase::AddAssessor::SchemeNotFoundException
        status 404
        single_error_response('NOT_FOUND', 'The requested scheme was not found')
      when UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
        status 409
        single_error_response(
          'ASSESSOR_ID_ON_ANOTHER_SCHEME',
          'The assessor ID you are trying to update is registered by a different scheme'
        )
      when JSON::Schema::ValidationError, JSON::ParserError
        status 400
        single_error_response('INVALID_REQUEST', e.message)
      else
        status 500
        single_error_response('SERVER_ERROR', e.message)
      end
    end
  end
end
