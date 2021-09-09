module UseCase
  class NotifyAssessmentAddressIdUpdateToDataWarehouse
    class CouldNotCompleteError < StandardError; end

    def initialize(redis_gateway:)
      @redis_gateway = redis_gateway
    end

    def execute(assessment_id:)
      @redis_gateway.push_to_queue("assessments", assessment_id)
    rescue Gateway::RedisGateway::PushFailedError => e
      raise CouldNotCompleteError, "Notifying assessment ID #{assessment_id} failed; error from gateway: #{e.message}"
    end
  end
end