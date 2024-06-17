module UseCase
  class ReloadAssessmentStatistics
    def initialize(gateway:)
      @gateway = gateway
    end

    def execute
      @gateway.reload_data
    end
  end
end
