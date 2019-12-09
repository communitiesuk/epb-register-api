module Controller
  require_relative '../container'
  require 'sinatra/cross_origin'

  class AssessorController < Sinatra::Base

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
  end
end
