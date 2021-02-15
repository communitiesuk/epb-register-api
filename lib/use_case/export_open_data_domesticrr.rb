module UseCase
  class ExportOpenDataDomesticrr
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    def execute(date_from, task_id = 0)
      data = []
      new_task_id = @log_gateway.fetch_new_task_id(task_id)
      assessments =
        @gateway.assessments_for_open_data(date_from, %w[RdSAP SAP], new_task_id)

      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])

        wrapper =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        wrapper_hash = wrapper.to_recommendation_report

        wrapper_hash[:recommendations].each do |recommendations|
        recommendations[:assessment_id] = Helper::RrnHelper.hash_rrn(assessment["assessment_id"])
      end

        data << wrapper_hash

        @log_gateway.create(
            assessment["assessment_id"],
            new_task_id,
            %w[RdSAP SAP],
            )
      end
      data
    end
  end
end
