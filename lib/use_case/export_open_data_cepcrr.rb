require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataCepcrr
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    # @TODO: use argument signature of this method
    def execute
      view_model_array = []

      # #use gateway to make db calls
      # call gateway to get data set
      assessments =
        @gateway.assessments_for_open_data_recommendation_report("CEPC-RR")

      # use existing gateway to get each xml doc from db line by line to ensure memory is totllay consumed by size of data returned
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
          item.each do |hash|
            view_model_array <<
              hash.merge(
                {
                  rrn: assessment["assessment_id"],
                  recommendation_item: recommendation_item,
                },
              )
            recommendation_item += 1
          end
        end

        # @TODO:update log table
      end

      # call method to return data as csv
      view_model_array.sort_by! { |key| key[:recommendation_item] }
    end
  end
end
