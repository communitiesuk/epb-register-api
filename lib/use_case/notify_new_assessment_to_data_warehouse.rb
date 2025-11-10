module UseCase
  class NotifyNewAssessmentToDataWarehouse
    class CouldNotCompleteError < StandardError; end

    def initialize(redis_gateway:)
      @data_warehouse_queues_gateway = redis_gateway
    end

    def execute(assessment_id:, is_scottish: false)
      unless is_scottish
        @data_warehouse_queues_gateway.push_to_queue(:assessments, assessment_id)
      end
    rescue Gateway::DataWarehouseQueuesGateway::PushFailedError => e
      raise CouldNotCompleteError, "Notifying assessment ID #{assessment_id} failed; error from gateway: #{e.message}"
    end
  end
end
