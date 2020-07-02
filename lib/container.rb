require "sinatra/activerecord"

class Container
  def initialize
    search_addresses_by_address_id_use_case =
      UseCase::SearchAddressesByAddressId.new

    search_addresses_by_postcode_use_case =
      UseCase::SearchAddressesByPostcode.new

    search_addresses_by_street_and_town_use_case =
      UseCase::SearchAddressesByStreetAndTown.new

    validate_and_lodge_assessment_use_case =
      UseCase::ValidateAndLodgeAssessment.new

    @objects = {
      validate_and_lodge_assessment_use_case:
        validate_and_lodge_assessment_use_case,
      search_addresses_by_address_id_use_case:
        search_addresses_by_address_id_use_case,
      search_addresses_by_postcode_use_case:
        search_addresses_by_postcode_use_case,
      search_addresses_by_street_and_town_use_case:
        search_addresses_by_street_and_town_use_case,
    }
  end

  def get_object(key)
    @objects[key]
  end
end
