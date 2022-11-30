module UseCase
  class NotifyAssessmentStatusUpdateToDataWarehouse
    def initialize(redis_gateway:)
      @data_warehouse_queues_gateway = redis_gateway
    end

    def execute(assessment_id:)
      @data_warehouse_queues_gateway.push_to_queue(:cancelled, assessment_id)
    end
  end
end
