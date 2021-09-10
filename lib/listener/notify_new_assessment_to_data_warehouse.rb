module Listener
  class NotifyNewAssessmentToDataWarehouse
    def initialize(notify_use_case:)
      @notify_use_case = notify_use_case
    end

    def assessment_lodged(assessment_id:)
      @notify_use_case.execute(assessment_id: assessment_id)
    end
  end
end
