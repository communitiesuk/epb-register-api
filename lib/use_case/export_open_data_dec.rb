require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataDec
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    # @TODO: pass arguments to filter for decs
    def execute(args = {})
      view_model_array = []

      # use gateway to make db calls
      # call gateway to get data set
      assessments = @gateway.assessments_for_open_data(args)

      # use existing gateway to get each xml doc from db line by line to ensure memory is not overloaded by size of data returned
      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])
        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        view_model_array << view_model.to_report
        # @TODO:update log table
      end

      # call method to return data as csv
      view_model_array
    end
  end
end
