module UseCase
  class FetchAssessment
    class NotFoundException < StandardError; end

    def initialize(
      assessments_gateway,
      assessors_gateway,
      green_deal_plans_gateway,
      assessments_xml_gateway = false
    )
      @assessments_gateway = assessments_gateway
      @assessors_gateway = assessors_gateway
      @green_deal_plans_gateway = green_deal_plans_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(assessment_id, xml = false)
      assessment = @assessments_gateway.fetch(assessment_id)

      raise NotFoundException unless assessment

      return @assessments_xml_gateway.fetch(assessment_id) if xml

      assessor = @assessors_gateway.fetch(assessment.get(:scheme_assessor_id))

      assessment.set(:assessor, assessor)

      green_deal_data = @green_deal_plans_gateway.fetch(assessment_id)

      unless green_deal_data == []
        assessment.set(:green_deal_plan, green_deal_data)
      end

      assessment
    end
  end
end
