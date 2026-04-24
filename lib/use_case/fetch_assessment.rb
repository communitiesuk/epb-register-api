module UseCase
  class FetchAssessment
    class NotFoundException < StandardError
    end

    class AssessmentGone < StandardError
    end

    class SchemeIdsDoNotMatch < StandardError
    end

    def initialize(assessments_gateway: nil, assessors_gateway: nil, assessments_xml_gateway: nil)
      @assessments_gateway = assessments_gateway || Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = assessors_gateway || Gateway::AssessorsGateway.new
      @assessments_xml_gateway = assessments_xml_gateway || Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id, auth_scheme_ids, is_scottish: false)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, restrictive: false, is_scottish: is_scottish

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGone
      end

      assessment_scheme_assessor_id = assessment.get(:scheme_assessor_id)
      assessor_details =
        @assessors_gateway.fetch(assessment_scheme_assessor_id)
      scheme_id = assessor_details.registered_by_id

      raise SchemeIdsDoNotMatch unless auth_scheme_ids.include?(scheme_id)

      @assessments_xml_gateway.fetch(assessment_id, is_scottish: is_scottish)[:xml]
    end
  end
end
