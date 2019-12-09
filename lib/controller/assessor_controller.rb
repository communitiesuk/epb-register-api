module Controller
  require_relative '../container'
  require 'sinatra/cross_origin'

  class AssessorController < Sinatra::Base
    PUT_SCHEMA = {
      type: 'object',
      required: %w[firstName lastName dateOfBirth],
      properties: { firstName: { type: 'string' } }
    }

    def initialize(toggles = false)
      super
      @json_helper = Helper::JsonHelper.new
      @toggles = toggles || Toggles.new
      @container = Container.new
    end

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
      when UseCase::FetchAssessor::AssessorNotFoundException
        status 404
      else
        status 500
        @json_helper.convert_to_json(
          { errors: [{ code: 'SERVER_ERROR', title: e.message }] }
        )
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
        @json_helper.convert_to_json({ errors: [{ code: 'SCHEME_NOT_FOUND' }] })
      when UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
        status 409
        @json_helper.convert_to_json(
          { errors: [{ code: 'ASSESSOR_ID_ON_ANOTHER_SCHEME' }] }
        )
      when JSON::Schema::ValidationError
        status 400
        { errors: [{ code: 'INVALID_REQUEST', title: e.message }] }
      else
        status 400
        @json_helper.convert_to_json({ errors: [{ code: 'INVALID_REQUEST' }] })
      end
    end
  end
end
