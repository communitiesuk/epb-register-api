module UseCase
  class SearchAddressesByPostcode
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(postcode:)
      @address_search_gateway.search_by_postcode postcode
    end
  end
end
