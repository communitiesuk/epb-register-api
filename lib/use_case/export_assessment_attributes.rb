module UseCase
  class ExportAssessmentAttributes
    def initialize(assessment_gateway, xml_gateway)
      @assessment_gateway = assessment_gateway
      @xml_gateway = xml_gateway
    end

    def execute(date_from, date_to = DateTime.now)
      assessments = []
      assessments_ids =
        @assessment_gateway.fetch_assessment_ids_by_range(date_from, date_to)

      assessments_ids.each { |_assessment| assessments << {} }

      assessments
    end
  end
end
