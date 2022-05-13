module UseCase
  class FindAssessmentsForBusByUprn
    class NotFoundException < StandardError; end

    def initialize(bus_gateway:)
      @bus_gateway = bus_gateway
    end

    def execute(uprn:)
      @bus_gateway.search_by_uprn(uprn)
    end
  end
end
