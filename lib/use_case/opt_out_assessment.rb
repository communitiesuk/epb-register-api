# frozen_string_literal: true

module UseCase
  class OptOutAssessment
    class AssessmentNotFound < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          false,
        ).first

      raise AssessmentNotFound unless assessment

      @assessments_gateway.update_field(assessment_id, "opt_out", true)
    end
  end
end
