# frozen_string_literal: true

module UseCase
  class OptOutAssessment
    class AssessmentNotFound < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
    end

    def execute(assessment_id, opt_out_status)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      main_assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          restrictive: false,
        ).first

      raise AssessmentNotFound unless main_assessment

      assessments = [main_assessment]
      linked_assessment_id =
        @assessments_gateway.get_linked_assessment_id(assessment_id)

      unless linked_assessment_id.nil?
        linked_assessment =
          @assessments_search_gateway.search_by_assessment_id(
            linked_assessment_id,
            restrictive: false,
          ).first
        assessments << linked_assessment
      end

      assessment_ids =
        assessments.map { |assessment| assessment.get("assessment_id") }
      @assessments_gateway.update_statuses(assessment_ids, "opt_out", opt_out_status)
    end
  end
end
