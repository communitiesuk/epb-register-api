module UseCase
  class SearchAddressesByStreetAndTown
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(street:, town:, address_type: nil)
      @address_search_gateway.search_by_street_and_town street,
                                                        town,
                                                        address_type
    end
  end
end
