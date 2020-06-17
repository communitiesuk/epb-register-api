# frozen_string_literal: true

module UseCase
  class UpdateAssessmentStatus
    def initialize(assessments_gateway)
      @assessments_gateway = assessments_gateway
    end

    def execute(assessment_id, status)
      if status == "CANCELLED"
        @assessments_gateway.update_field(
          assessment_id,
          "cancelled_at",
          Time.now.to_s,
        )
      end
    end
  end
end
