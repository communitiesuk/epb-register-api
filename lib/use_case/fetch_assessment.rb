module UseCase
  class FetchAssessment
    class NotFoundException < StandardError; end
    class AssessmentGone < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @green_deal_plan_gateway = Gateway::GreenDealPlansGateway.new
      @related_assessments_gateway = Gateway::RelatedAssessmentsGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGone
      end

      @assessments_xml_gateway.fetch(assessment_id)[:xml]
    end
  end
end
