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

    get "/api/scotland/v1/updates/new-reports", auth_token_has_all: %w[scotland_data:rrn:list] do
      params = params_body DATE_RANGE_SCHEMA

      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      raise Boundary::InvalidDates if start_date > end_date
      raise Boundary::InvalidArgument, "date range includes today" if end_date >= Date.today

      current_page = params[:page] ? params[:page].to_i : 1

      data = ApiFactory.fetch_new_reports_use_case.execute(start_date: start_date, end_date: end_date, current_page: current_page)
      pagination = ApiFactory.get_pagination_for_new_reports.execute(start_date: start_date, end_date: end_date, current_page: current_page, url: request.url)

      json_api_response(code: 200, pagination: pagination, data: data)
    rescue StandardError => e
      case e
      when Boundary::NoData
        error_response 404, "NOT_FOUND", "Date range did not return any data"
      when Boundary::InvalidDates
        error_response 400, "INVALID_REQUEST", "A required argument is is invalid: #{e.message}"
      when Boundary::InvalidArgument
        error_response 400, "INVALID_REQUEST", e.message
      when Boundary::Json::ValidationError
        error_response 400, "INVALID_REQUEST", e.message
      when Errors::OutOfPaginationRangeError
        error_response 400, "PAGINATION_ERROR", e.message
      else
        server_error(e)
      end
    end

    get "/api/scotland/v1/updates/assessments/status", auth_token_has_all: %w[scotland_data:assessment_status:list] do
      params = params_body DATE_RANGE_SCHEMA

      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      raise Boundary::InvalidDates if start_date > end_date
      raise Boundary::InvalidArgument, "date range includes today" if end_date >= Date.today

      current_page = params[:page] ? params[:page].to_i : 1

      event_types = %w[scottish_opt_out scottish_opt_in scottish_cancelled]

      data = ApiFactory.fetch_scottish_assessment_status_updates.execute(event_types:, start_date:, end_date: end_date, current_page: current_page)
      pagination = ApiFactory.get_pagination_for_scottish_assessment_status_updates.execute(event_types:, start_date: start_date, end_date: end_date, current_page: current_page, url: request.url, count_method: :count_scottish_events)

      json_api_response(code: 200, pagination: pagination, data: data)
    rescue StandardError => e
      case e
      when Boundary::NoData
        error_response 404, "NOT_FOUND", "Date range did not return any data"
      when Boundary::InvalidDates
        error_response 400, "INVALID_REQUEST", "A required argument is is invalid: #{e.message}"
      when Boundary::InvalidArgument
        error_response 400, "INVALID_REQUEST", e.message
      when Boundary::Json::ValidationError
        error_response 400, "INVALID_REQUEST", e.message
      when Errors::OutOfPaginationRangeError
        error_response 400, "PAGINATION_ERROR", e.message
      else
        server_error(e)
      end
    end

    get "/api/scotland/v1/assessments/:assessmentId/meta-data",
        auth_token_has_all: %w[scotland_data:assessment_meta:fetch] do
      params_body ASSESSMENT_ID_SCHEMA
      assessment_id = params[:assessmentId]
      summary = UseCase::AssessmentMeta.new(Gateway::AssessmentMetaGateway.new).execute(assessment_id, is_scottish: true)

      json_api_response(data: summary, meta: { data_sent_at: Time.now })
    rescue StandardError => e
      case e
      when UseCase::AssessmentMeta::NoDataException
        error_response(404, "NOT_FOUND", "Assessment ID did not return any data")
      when Boundary::Json::ValidationError
        error_response 400, "BAD_REQUEST", "The value provided for the assessment ID in the endpoint URL was not valid"
      else
        server_error(e)
      end
    end
  end
end
