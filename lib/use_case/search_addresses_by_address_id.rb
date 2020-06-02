module UseCase
  class SearchAddressesByAddressId
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(address_id:)
      rrn = address_id[4..-1]
      @address_search_gateway.search_by_rrn rrn
    end
  end
end
