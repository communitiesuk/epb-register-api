module UseCase
  class ExportOpenDataDomesticrr
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(date_from, task_id = 0)
      data = []
      assessments =
        @gateway.assessments_for_open_data(date_from, %w[RdSAP SAP], task_id)

      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])

        wrapper =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        wrapper_hash = wrapper.to_recommendation_report
        data << wrapper_hash
      end
      data.sort_by! { |key| key[:assessment_id] }
    end
  end
end
