# frozen_string_literal: true

module Controller
  class ReportingController < Controller::BaseController
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
      raw_data =
        body UseCase::GetAssessmentCountBySchemeNameAndType.new.execute(
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
  end
end
