module UseCase
  class NotifyAssessmentAddressIdUpdateToDataWarehouse
    class CouldNotCompleteError < StandardError; end

    def initialize(redis_gateway:)
      @data_warehouse_queues_gateway = redis_gateway
    end

    def execute(assessment_id:, address_id:)
      payload = "#{assessment_id}:#{address_id}"
      @data_warehouse_queues_gateway.push_to_queue(:assessments_address_update, payload)
    rescue Gateway::DataWarehouseQueuesGateway::PushFailedError => e
      raise CouldNotCompleteError, "Notifying assessment ID #{assessment_id} failed; error from gateway: #{e.message}"
    end
  end
end
