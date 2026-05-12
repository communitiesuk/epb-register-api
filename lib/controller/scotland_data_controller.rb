# frozen_string_literal: true

module Controller
  class ScotlandDataController < Controller::BaseController
    DATE_RANGE_SCHEMA = {
      type: "object",
      required: %w[startDate endDate],
      properties: {
        startDate: {
          type: "string",
          format: "iso-date",
        },
        endDate: {
          type: "string",
          format: "iso-date",
        },
        page: {
          type: "string",
        },
      },
    }.freeze

    ASSESSMENT_ID_SCHEMA = {
      type: "object",
      required: %w[assessmentId],
      properties: {
        assessmentId: {
          type: "string",
          pattern: Helper::RegexHelper::RRN,
        },
      },
    }.freeze

    get "/api/scotland/v1/updates/new-reports", auth_token_has_all: %w[scotland_data:fetch] do
      filter_date_params

      data = ApiFactory.fetch_new_reports_use_case.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page)
      pagination = ApiFactory.get_pagination_for_new_reports.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page, url: request.url)

      json_api_response(code: 200, links: pagination, data: data)
    rescue StandardError => e
      rescue_errors(e)
    end

    get "/api/scotland/v1/updates/assessments/status", auth_token_has_all: %w[scotland_data:fetch] do
      filter_date_params

      event_types = %w[scottish_opt_out scottish_opt_in scottish_cancelled]

      data = ApiFactory.fetch_scottish_assessment_status_updates.execute(event_types:, start_date: @start_date, end_date: @end_date, current_page: @current_page)
      pagination = ApiFactory.get_pagination_for_scottish_assessment_status_updates.execute(event_types:, start_date: @start_date, end_date: @end_date, current_page: @current_page, url: request.url, count_method: :count_scottish_events)

      json_api_response(code: 200, links: pagination, data: data)
    rescue StandardError => e
      rescue_errors(e)
    end

    get "/api/scotland/v1/assessments/:assessmentId/meta-data",
        auth_token_has_all: %w[scotland_data:fetch] do
      params_body ASSESSMENT_ID_SCHEMA
      assessment_id = params[:assessmentId]
      summary = UseCase::AssessmentMeta.new(Gateway::AssessmentMetaGateway.new).execute(assessment_id, is_scottish: true)

      json_api_response(data: summary, meta: { data_sent_at: Time.now })
    rescue StandardError => e
      case e
      when UseCase::AssessmentMeta::NoDataException
        not_found_error("Assessment ID did not return any data")
      when Boundary::Json::ValidationError
        error_response 400, "BAD_REQUEST", "The requested assessment id is not valid"
      else
        server_error(e)
      end
    end

    get "/api/scotland/v1/assessments/:assessment_id/xml-data",
        auth_token_has_all: %w[scotland_data:fetch] do
      assessment_id = params[:assessment_id]

      result =
        UseCase::FetchAssessmentForScotlandPortal.new(assessments_xml_gateway: Gateway::AssessmentsXmlGateway.new)
                                                 .execute(assessment_id)

      xml_response result, 200
    rescue StandardError => e
      case e
      when UseCase::FetchAssessmentForScotlandPortal::NotFoundException
        not_found_error("Assessment ID did not return any data")
      when Helper::RrnHelper::RrnNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment id is not valid",
        )
      else
        server_error(e)
      end
    end

    get "/api/scotland/v1/updates/assessors/status", auth_token_has_all: %w[scotland_data:fetch] do
      filter_date_params

      data = ApiFactory.fetch_scottish_assessor_status_updates.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page)
      pagination = ApiFactory.get_pagination_for_scottish_assessor_status_updates.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page, url: request.url, count_method: :count_scottish_assessor_events)

      json_api_response(code: 200, links: pagination, data: data)
    rescue StandardError => e
      rescue_errors(e)
    end

    get "/api/scotland/v1/updates/new-assessors", auth_token_has_all: %w[scotland_data:fetch] do
      filter_date_params

      data = ApiFactory.fetch_scottish_assessor_by_date.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page)
      pagination = ApiFactory.get_pagination_for_scottish_assessors_by_date.execute(start_date: @start_date, end_date: @end_date, current_page: @current_page, url: request.url, count_method: :count_search_by_date)

      json_api_response(code: 200, links: pagination, data: data)
    rescue StandardError => e
      rescue_errors(e)
    end

  private

    def rescue_errors(error)
      case error
      when Boundary::InvalidDates
        error_response 400, "INVALID_REQUEST", "A required argument is is invalid: #{error.message}"
      when Boundary::InvalidArgument
        error_response 400, "INVALID_REQUEST", error.message
      when Boundary::Json::ValidationError
        error_response 400, "INVALID_REQUEST", error.message
      when Errors::OutOfPaginationRangeError
        error_response 400, "PAGINATION_ERROR", error.message
      else
        server_error(error)
      end
    end

    def filter_date_params
      @params = params_body DATE_RANGE_SCHEMA

      @start_date = Date.parse(@params[:start_date])
      @end_date = Date.parse(@params[:end_date])

      raise Boundary::InvalidDates if @start_date > @end_date
      raise Boundary::InvalidArgument, "date range includes today" if @end_date >= Date.today

      @current_page = @params[:page] ? @params[:page].to_i : 1
    end
  end
end
