module UseCase
  class NotifyAssessmentStatusUpdateToDataWarehouse
    def initialize(redis_gateway:)
      @redis_gateway = redis_gateway
    end

    def execute(assessment_id:)
      @redis_gateway.push_to_queue("cancelled", assessment_id)
    end
  end
end
