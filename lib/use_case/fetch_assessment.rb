module UseCase
  class FetchAssessment
    class NotFoundException < StandardError; end
    class AssessmentGone < StandardError; end

    def initialize(
      assessments_gateway,
      assessments_xml_gateway = false
    )
      @assessments_gateway = assessments_gateway
      @assessors_gateway = Gateway::AssessorsGateway.new
      @green_deal_plans_gateway = Gateway::GreenDealPlansGateway.new
      @related_assessments_gateway = Gateway::RelatedAssessmentsGateway.new
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(assessment_id, xml = false)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGone
      end

      return @assessments_xml_gateway.fetch(assessment_id) if xml

      assessor = @assessors_gateway.fetch(assessment.get(:scheme_assessor_id))

      assessment.set(:assessor, assessor)

      unless assessment.get(:address_id).nil?
        related_assessments =
          @related_assessments_gateway.fetch_related_assessments(
            assessment.get(:address_id),
          )
      end

      assessment.set(:related_assessments, related_assessments)

      green_deal_data = @green_deal_plans_gateway.fetch(assessment_id)

      unless green_deal_data == []
        assessment.set(:green_deal_plan, green_deal_data)
      end

      assessment
    end
  end
end
