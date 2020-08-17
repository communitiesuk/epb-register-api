module UseCase
  class SearchAddressesByAddressId
    def execute(address_id:)
      if address_id.start_with?("RRN")
        rrn = address_id[4..-1]
        Gateway::AddressSearchGateway.new.search_by_rrn rrn
      elsif address_id.start_with?("UPRN")
        uprn = address_id[5..-1]
        Gateway::AddressBaseSearchGateway.new.search_by_uprn uprn
      end
    end
  end
end
