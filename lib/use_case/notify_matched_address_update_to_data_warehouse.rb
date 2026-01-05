module UseCase
  class NotifyMatchedAddressUpdateToDataWarehouse
    class CouldNotCompleteError < StandardError; end

    def initialize(redis_gateway:)
      @data_warehouse_queues_gateway = redis_gateway
    end

    def execute(assessment_id:, matched_uprn:)
      payload = "#{assessment_id}:#{matched_uprn}"
      @data_warehouse_queues_gateway.push_to_queue(:matched_address_update, payload)
    rescue Gateway::DataWarehouseQueuesGateway::PushFailedError => e
      raise CouldNotCompleteError, "Notifying assessment ID #{assessment_id} failed; error from gateway: #{e.message}"
    end
  end
end
