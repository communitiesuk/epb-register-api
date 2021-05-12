require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataDecrr
    ASSESSMENT_TYPE = "DEC-RR".freeze

    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    def execute(date_from, task_id = 0, date_to = DateTime.now)
      view_model_array = []
      new_task_id = @log_gateway.fetch_new_task_id(task_id)

      assessments =
        @gateway.assessments_for_open_data_recommendation_report(
          date_from,
          "DEC-RR",
          new_task_id,
          date_to,
        )

      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])

        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )

        report = view_model.to_report

        # recs are an array that can cantian arrays of recs
        rr_report_array = report[:recommendations]
        recommendation_item = 1

        next unless rr_report_array

        rr_report_array.each do |item|
          view_model_array <<
            item.merge(
              {
                assessment_id:
                  Helper::RrnHelper.hash_rrn(
                    assessment["linked_assessment_id"],
                  ),
                recommendation_item: recommendation_item,
              },
            )
          recommendation_item += 1
        end

        @log_gateway.create(
          assessment["assessment_id"],
          new_task_id,
          ASSESSMENT_TYPE,
        )
      end

      view_model_array
    end
  end
end
