require "nokogiri"

module UseCase
  class ExportOpenDataDomestic
    ASSESSMENT_TYPE = %w[RdSAP SAP].freeze

    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
      @log_gateway = Gateway::OpenDataLogGateway.new
    end

    def execute(date_from, task_id = 0, date_to = DateTime.now)
      page_number = 0
      data = []
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
        next if xml_data[:schema_type].include?("NI")

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
          assessment["created_at"]&.strftime("%F %H:%M:%S")
        @log_gateway.create(
          assessment["assessment_id"],
          new_task_id,
          Helper::ExportHelper.report_type_to_s(ASSESSMENT_TYPE),
        )
        view_model_hash[:assessment_id] =
          Helper::RrnHelper.hash_rrn(assessment["assessment_id"])
        unless view_model_hash[:building_reference_number].nil?
          unless view_model_hash[:building_reference_number].include?("UPRN")
            view_model_hash[:building_reference_number] = nil
          end
        end

        data << view_model_hash
        page_number += 1
      end
      data
    end
  end
end
