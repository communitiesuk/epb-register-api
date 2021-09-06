module UseCase
  class NotifyNewAssessmentToDataWarehouse
    def initialize(redis_gateway:)
      @redis_gateway = redis_gateway
    end

    def execute(assessment_id:)
      @redis_gateway.push_to_queue("assessments", assessment_id)
    end
  end
end
