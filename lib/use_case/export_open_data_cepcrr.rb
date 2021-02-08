require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataCepcrr
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    # @TODO: use argument signature of this method
    def execute(date_from = "2019-07-01")
      view_model_array = []

      # #use gateway to make db calls
      # call gateway to get data set
      assessments =
        @gateway.assessments_for_open_data_recommendation_report(
          "CEPC-RR",
          date_from,
        )

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

        recommendation_item = 1

        next unless report[:recommendations]

        report[:recommendations].each do |recommendation|
          view_model_array <<
            recommendation.merge(
              {
                rrn: assessment["assessment_id"],
                recommendation_item: recommendation_item,
              },
            )
          recommendation_item += 1
        end

        # @TODO:update log table
      end

      # call method to return data as csv
      view_model_array.sort_by! { |key| key[:recommendation_item] }
    end
  end
end
