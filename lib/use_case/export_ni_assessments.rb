module UseCase
  class ExportNiAssessments
    def initialize(ni_export_gateway:, xml_gateway:)
      @ni_export_gateway = ni_export_gateway
      @xml_gateway  = xml_gateway
    end

    def execute(type_of_assessments)
      assessments = @ni_export_gateway.fetch_assessments(type_of_assessments)
      assessments.each do |assessment|
        @xml_gateway.fetch(assessment["assessment_id"])
      end
    end
  end
end
