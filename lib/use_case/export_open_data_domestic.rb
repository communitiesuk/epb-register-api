require "nokogiri"

module UseCase
  class ExportOpenDataDomestic
    def initialize
      @gateway = Gateway::ReportingGateway.new
      @assessment_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(_args = {})
      data = []

      # TODO: pass in both RdSAP and SAP to usecase
      assessments = @gateway.assessments_for_open_data("RdSAP")

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

        data << view_model_hash
      end
      data
    end
  end
end
