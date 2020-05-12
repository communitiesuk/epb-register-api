module UseCase
  class SearchAddressesByBuildingReferenceNumber
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(building_reference_number:)
      @address_search_gateway.search_by_rrn building_reference_number
    end
  end
end
