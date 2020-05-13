module UseCase
  class SearchAddressesByBuildingReferenceNumber
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(building_reference_number:)
      rrn = building_reference_number[4..-1]
      @address_search_gateway.search_by_rrn rrn
    end
  end
end
