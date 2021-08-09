module UseCase
  class AssessmentMeta
    def initialize(gateway)
      @gateway = gateway
    end

    def execute(assessment_id)
      @gateway.fetch(assessment_id)
    end
  end
end
