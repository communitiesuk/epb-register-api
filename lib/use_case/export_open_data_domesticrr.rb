module UseCase
  class ExportOpenDataDomesticrr
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    RR_HEADERS = {
      improvement_summary: "improvement_summary_text",
      improvement_description: "improvement_descr_text",
      improvement_item: "improvement_summary",
      sequence: "improvement_item",
      improvement_code: "improvement_id",
    }.freeze

    def execute(date_from, task_id = 0)
      recommendations = []
      new_task_id = @log_gateway.fetch_new_task_id(task_id)
      assessments =
        @gateway.assessments_for_open_data(
          date_from,
          %w[RdSAP SAP],
          new_task_id,
        )

      assessments.each do |assessment|
        xml_data = @assessment_gateway.fetch(assessment["assessment_id"])
        next if xml_data[:schema_type].include?("NI")

        wrapper =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        wrapper_hash = wrapper.to_recommendation_report

        update_recommendation_headers(recommendations, wrapper_hash[:recommendations].flatten)

        @log_gateway.create(
          assessment["assessment_id"],
          new_task_id,
          %w[RdSAP SAP],
        )
      end
      recommendations
    end

  private

    def update_recommendation_headers(recommendations, array_wrapper)
      array_wrapper.each do |hash|
        new_hash = {}
        hash.each do |key, value|
          new_key = RR_HEADERS[key]
          if new_key.nil?
            new_hash[key.to_sym] = value
          else
            new_hash[new_key.to_sym] = value
          end
        end
        assessment_id = new_hash[:assessment_id]
        new_hash[:assessment_id] = Helper::RrnHelper.hash_rrn(assessment_id)

        recommendations << new_hash
      end
    end
  end
end
