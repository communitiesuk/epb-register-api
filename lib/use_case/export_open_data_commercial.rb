require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataCommercial
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    # @TODO: use argument signature of this method
    def execute()
      view_model_array = []
      # use gateway to make db calls
      # call gateway to get data set
      assessments = @gateway.assessments_for_open_data("CEPC")
      # use existing gateway to get each xml doc from db line by line to ensure memory is totllay consumed by size of data returned
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
          assessment["created_at"].strftime("%F")
        view_model_hash[:lodgement_datetime] =
          assessment["created_at"].strftime("%F %H:%M:%S")

        # lodgement_datetime
        view_model_array << view_model_hash
        # @TODO:update log table
      end

      # call method to return data as csv
      # to_csv
      view_model_array
    end

  private

    # @TODO:move CSV prod code and tests to presentation layer (Rake)


    # def execute(args = {})

    # def execute(args = {})
    #   args[:start] = 0
    #   data = []
    #   results = []
    #   while args[:start] <= args[:number_of_assessments].to_i
    #     assessments = @gateway.assessments_xml_for_open_data(args)
    #
    #     assessments.each { |assessment|
    #       report_model =
    #         ViewModel::Factory.new.create(
    #           assessment["xml"],
    #           assessment["schema_type"],
    #           assessment["assessment_id"],
    #           )
    #
    #       data << report_model.to_report
    #     }
    #
    #     results <<
    #       CSV.generate(
    #         write_headers: (args[:start] == 0),
    #         headers: data.first ? data.first.keys : [],
    #         ) { |csv| data.each { |row| csv << row } }
    #
    #     args[:start] += args[:batch].to_i
    #
    #     if args[:max_runs] && args[:max_runs].to_i <= args[:start]
    #       # puts "Exiting as max runs was reached"
    #       break
    #     end
    #   end
    #   results[0].upcase
    #   results
    # end
  end
end
