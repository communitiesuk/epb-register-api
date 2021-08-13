module UseCase
  class FetchAssessment
    class NotFoundException < StandardError
    end

    class AssessmentGone < StandardError
    end

    class SchemeIdsDoNotMatch < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id, auth_scheme_ids)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGone
      end

      assessement_scheme_assessor_id = assessment.get(:scheme_assessor_id)
      assessor_details =
        @assessors_gateway.fetch(assessement_scheme_assessor_id)
      scheme_id = assessor_details.registered_by_id

      raise SchemeIdsDoNotMatch unless auth_scheme_ids.include?(scheme_id)

      @assessments_xml_gateway.fetch(assessment_id)[:xml]
    end
  end
end
