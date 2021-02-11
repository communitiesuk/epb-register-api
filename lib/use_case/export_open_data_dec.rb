require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataDec
    ASSESSMENT_TYPE = "DEC".freeze

    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    def execute(task_id = 0, date_from)
      view_model_array = []
      new_task_id = @log_gateway.fetch_new_task_id(task_id)

      assessments =
        @gateway.assessments_for_open_data("DEC", new_task_id, date_from)
      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])
        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        view_model_hash = view_model.to_report
        view_model_hash[:lodgement_date] =
          assessment["date_registered"].strftime("%F")
        view_model_hash[:lodgement_datetime] =
          assessment["date_registered"].strftime("%F %H:%M:%S")
        view_model_hash[:rrn] =
          Helper::RrnHelper.hash_rrn(assessment["assessment_id"])

        view_model_array << view_model_hash
        @log_gateway.create(assessment["assessment_id"], new_task_id, "DEC")
      end

      view_model_array
    end
  end
end
