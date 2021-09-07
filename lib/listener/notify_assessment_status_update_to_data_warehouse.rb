module Listener
  class NotifyAssessmentStatusUpdateToDataWarehouse
    def initialize(notify_use_case:)
      @notify_use_case = notify_use_case
    end

    def assessment_cancelled(assessment_id:)
      notify_status_update assessment_id
    end

    def assessment_marked_not_for_issue(assessment_id:)
      notify_status_update assessment_id
    end

  private

    def notify_status_update(assessment_id)
      @notify_use_case.execute(assessment_id: assessment_id)
    end
  end
end
