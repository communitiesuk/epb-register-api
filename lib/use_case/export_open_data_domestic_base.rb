require "nokogiri"

module UseCase
  class ExportOpenDataDomesticBase
    ASSESSMENT_TYPE = %w[RdSAP SAP].freeze

    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    end

  private

    def fetch_and_format_data(assessments, new_task_id)
      reports = []
      assessments.each_with_index do |assessment, _index|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])

        next if xml_data[:schema_type].include?("NI")

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
        @log_gateway.create(
          assessment["assessment_id"],
          new_task_id,
          Helper::ExportHelper.report_type_to_s(ASSESSMENT_TYPE),
        )
      end

      reports
    end
  end
end
