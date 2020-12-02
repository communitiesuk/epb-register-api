# frozen_string_literal: true

module Controller
  class ReportingController < Controller::BaseController
    DATE_RANGE_SCHEMA = {
      type: "object",
      required: %w[startDate endDate],
      properties: {
        startDate: { type: "string", format: "iso-date" },
        endDate: { type: "string", format: "iso-date" },
      },
    }.freeze

    get "/api/reports/assessments/region-and-type",
        jwt_auth: %w[reporting:assessment_by_type_and_region] do
      raw_data =
        body UseCase::GetAssessmentCountByRegionAndType.new.execute(
          Date.parse(params["start_date"]),
          Date.parse(params["end_date"]),
        )

      content_type "text/csv"
      attachment params["start_date"] + "_to_" + params["end_date"] + ".csv"

      if raw_data.empty?
        json_response(200, { data: "No lodgements during this time frame" })
      else
        content_type "text/csv"
        attachment params["start_date"] + "_to_" + params["end_date"] + ".csv"
        body CSV.generate(
          write_headers: true, headers: raw_data.first.keys,
        ) { |csv| raw_data.each { |row| csv << row } }
      end
    end

    get "/api/reports/assessments/scheme-and-type",
        jwt_auth: %w[reporting:assessment_by_scheme_and_type] do

      params = params_body DATE_RANGE_SCHEMA

      raw_data =
        body UseCase::GetAssessmentCountBySchemeNameAndType.new.execute(
          Date.parse(params[:startDate]),
          Date.parse(params[:endDate]),
        )

      if raw_data.empty?
        json_response(200, { data: "No lodgements during this time frame" })
      else
        content_type "text/csv"
        attachment params[:startDate] + "_to_" + params[:endDate] + ".csv"
        body CSV.generate(
          write_headers: true, headers: raw_data.first.keys,
        ) { |csv| raw_data.each { |row| csv << row } }
      end
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, "INVALID_REQUEST", e.message)
      else
        server_error(e.message)
      end
    end
  end
end
