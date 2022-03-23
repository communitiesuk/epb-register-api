module UseCase
  class ExportNiAssessments
    def initialize(export_ni_gateway:, xml_gateway:)
      @ni_export_gateway = export_ni_gateway
      @xml_gateway = xml_gateway
    end

    def execute(type_of_assessment:, date_from: "1990-01-01", date_to: Time.now)
      assessments_array = []

      assessments = @ni_export_gateway.fetch_assessments(type_of_assessment: type_of_assessment, date_from: date_from, date_to: date_to)

      assessments.each do |assessment|
        xml_data = @xml_gateway.fetch(assessment["assessment_id"])

        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
          )
        view_model_data = type_of_assessment == %w[CEPC] ? view_model.to_report : view_model.to_hash_ni
        combined_data = view_model_data.merge(assessment.symbolize_keys)
        assessments_array << combined_data
      end
      assessments_array
    end
  end
end
