# frozen_string_literal: true

module UseCase
  class UpdateAssessmentStatus
    class AssessmentNotFound < StandardError
    end

    class AssessmentAlreadyCancelled < StandardError
    end

    class AssessmentNotLodgedByScheme < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @assessments_search_gateway = Gateway::AssessmentsSearchGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
    end

    def execute(assessment_id, status, scheme_ids)
      main_assessment =
        @assessments_search_gateway.search_by_assessment_id(
          assessment_id,
          false,
        ).first

      raise AssessmentNotFound unless main_assessment

      assessments = [main_assessment]

      linked_assessment_id =
        @assessments_gateway.get_linked_assessment_id(assessment_id)

      unless linked_assessment_id.nil?
        linked_assessment =
          @assessments_search_gateway.search_by_assessment_id(
            linked_assessment_id,
            false,
          ).first

        unless linked_assessment.get(:cancelled_at) ||
            linked_assessment.get(:not_for_issue_at)
          assessments << linked_assessment
        end
      end

      validate_status_updates(assessments, scheme_ids)
      update_statuses(assessments, status)
    end

  private

    def validate_status_updates(assessments, scheme_ids)
      assessments.each do |assessment|
        if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
          raise AssessmentAlreadyCancelled
        end

        assessor = @assessors_gateway.fetch(assessment.get(:scheme_assessor_id))

        unless scheme_ids.include?(assessor.registered_by_id)
          raise AssessmentNotLodgedByScheme
        end
      end
    end

    def update_statuses(assessments, status)
      assessment_ids =
        assessments.map { |assessment| assessment.get("assessment_id") }

      if status == "CANCELLED"
        @assessments_gateway.update_statuses(
          assessment_ids,
          "cancelled_at",
          Time.now.to_s,
        )
      elsif status == "NOT_FOR_ISSUE"
        @assessments_gateway.update_statuses(
          assessment_ids,
          "not_for_issue_at",
          Time.now.to_s,
        )
      end
    end
  end
end
