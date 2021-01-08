module UseCase
  class SearchAddressesByAddressId
    def execute(address_id:)
      Gateway::AddressSearchGateway.new.search_by_address_id address_id
    end
  end
end
