module UseCase
  class FindAssessmentsForBusByAddress
    def initialize(bus_gateway:)
      @bus_gateway = bus_gateway
    end

    def execute(postcode:, building_identifier:)
      @bus_gateway.search_by_postcode_and_building_identifier(
        postcode: postcode,
        building_identifier: building_identifier,
      )
    end
  end
end
