module UseCase
  class SearchAddressesByStreetAndTown
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(street:, town:)
      @address_search_gateway.search_by_street_and_town street, town
    end
  end
end
