require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataDec
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    def execute(task_id, date_from)
      view_model_array = []

      # #use gateway to make db calls
      # call gateway to get data set
      assessments = @gateway.assessments_for_open_data("DEC", date_from)

      # use existing gateway to get each xml doc from db line by line to ensure memory is not consumed by size of data returned
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

        view_model_array << view_model_hash
        @log_gateway.insert(assessment["assessment_id"], task_id)
      end

      # call method to return data as csv
      # to_csv
      view_model_array
    end
  end
end
