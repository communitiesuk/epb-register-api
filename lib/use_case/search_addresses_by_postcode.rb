module UseCase
  class SearchAddressesByPostcode
    def initialize
      @address_search_gateway = Gateway::AddressSearchGateway.new
      @address_base_search_gateway = Gateway::AddressBaseSearchGateway.new
    end

    def execute(postcode:, building_name_number: nil, address_type: nil)
      assessment_addresses = @address_search_gateway.search_by_postcode postcode,
                                                 building_name_number,
                                                 address_type
      address_base_addresses = @address_base_search_gateway.search_by_postcode postcode,
                                                      building_name_number,
                                                      address_type
      assessment_addresses << address_base_addresses
      assessment_addresses.flatten
    end
  end
end
