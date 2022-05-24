module UseCase
  class FetchAssessmentForBus
    def initialize(bus_gateway:)
      @bus_gateway = bus_gateway
    end

    def execute(rrn:)
      @bus_gateway.search_by_rrn rrn
    end
  end
end
