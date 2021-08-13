module UseCase
  class FetchDecSummary
    class AssessmentNotFound < StandardError
    end

    class AssessmentGone < StandardError
    end

    class AssessmentNotDec < StandardError
    end

    def initialize
      @assessment_gateway = Gateway::AssessmentsSearchGateway.new
      @assessments_xml_gateway = Gateway::AssessmentsXmlGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      result =
        @assessment_gateway.search_by_assessment_id(assessment_id, false).first

      raise AssessmentNotFound unless result

      if %w[CANCELLED NOT_FOR_ISSUE].include? result.to_hash[:status]
        raise AssessmentGone
      end

      raise AssessmentNotDec if result.to_hash[:type_of_assessment] != "DEC"

      assessments_xml = @assessments_xml_gateway.fetch(assessment_id)

      dec_summary =
        ViewModel::DecSummaryWrapper.new(
          assessments_xml[:xml],
          assessments_xml[:schema_type],
        )

      dec_summary.to_xml
    end
  end
end
