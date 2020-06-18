# frozen_string_literal: true

module UseCase
  class UpdateAssessmentStatus
    class AssessmentNotLodgedByScheme < StandardError; end

    def initialize(assessments_gateway, assessors_gateway)
      @assessments_gateway = assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(assessment_id, status, scheme_ids)
      assessment =
        @assessments_gateway.search_by_assessment_id(assessment_id).first

      assessor = @assessors_gateway.fetch(assessment.get(:scheme_assessor_id))

      unless scheme_ids.include?(assessor.registered_by_id)
        raise AssessmentNotLodgedByScheme
      end

      if status == "CANCELLED"
        @assessments_gateway.update_field(
          assessment_id,
          "cancelled_at",
          Time.now.to_s,
        )
      end

      if status == "NOT_FOR_ISSUE"
        @assessments_gateway.update_field(
          assessment_id,
          "not_for_issue_at",
          Time.now.to_s,
        )
      end
    end
  end
end
