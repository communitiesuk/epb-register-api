module Listener
  class NotifyOptOutStatusUpdateToDataWarehouse
    def initialize(notify_use_case:)
      @notify_use_case = @notify_use_case
    end

    def assessment_opt_out_status_changed(assessment_id:)
      @notify_use_case.execute(assessment_id: assessment_id)
    end
  end
end
