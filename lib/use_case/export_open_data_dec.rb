require "nokogiri"
require "date"
module UseCase
  class ExportOpenDataDec
    ASSESSMENT_TYPE = "DEC".freeze

    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    end

    def execute(date_from, task_id = 0, date_to = Time.now.utc)
      reports = []
      new_task_id = @log_gateway.fetch_new_task_id(task_id)

      assessments =
        @gateway.assessments_for_open_data(
          date_from,
          ASSESSMENT_TYPE,
          new_task_id,
          date_to,
        )

      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])
        updated_address_id = @assessments_address_id_gateway.fetch(assessment["assessment_id"])[:address_id]

        additional_data = {
          address_id: updated_address_id,
          date_registered: assessment["date_registered"],
          created_at: assessment["created_at"],
          outcode_region: assessment["outcode_region"],
          postcode_region: assessment["postcode_region"],
        }
        additional_data.compact!

        wrapper =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
            additional_data,
          )

        report = wrapper.to_report
        report[:country] = assessment["country"]
        reports << report
        @log_gateway.create(assessment["assessment_id"], new_task_id, "DEC")
      end

      reports
    end
  end
end
