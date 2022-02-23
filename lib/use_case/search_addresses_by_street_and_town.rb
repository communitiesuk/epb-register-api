module UseCase
  class SearchAddressesByStreetAndTown

    MIN_STRING_LENGTH = 2

    def initialize(address_search_gateway = nil)
      @address_search_gateway = address_search_gateway || Gateway::AddressSearchGateway.new
    end

    def execute(street:, town:, address_type: nil)
      street = street.delete!("()|:*!") || street
      town = town.delete!("()|:*!") || town

      raise Boundary::Json::Error unless valid_sting_length?(street) && valid_sting_length?(town)

      @address_search_gateway.search_by_street_and_town street,
                                                        town,
                                                        address_type
    end

  private

    def valid_sting_length?(param)
      param.length >= MIN_STRING_LENGTH
    end
  end
end
