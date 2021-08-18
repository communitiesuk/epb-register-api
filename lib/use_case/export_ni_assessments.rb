module UseCase

  class ExportNiAssessments
    def initialize(export_ni_gateway:, xml_gateway:)
      @ni_export_gateway = export_ni_gateway
      @xml_gateway  = xml_gateway
    end

    def execute(type_of_assessments)
      assessments_array = []
      assessments = @ni_export_gateway.fetch_assessments(type_of_assessments)
      assessments.each do | assessment |
        xml_data = @xml_gateway.fetch(assessment["assessment_id"])

        view_model =
          ViewModel::Factory.new.create(
            xml_data[:xml],
            xml_data[:schema_type],
            assessment["assessment_id"],
            )
        assessments_array << view_model.to_hash

      end
      assessments_array

    end

  end

end
