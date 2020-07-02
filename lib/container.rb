require "sinatra/activerecord"

class Container
  def initialize
    validate_assessment_use_case = UseCase::ValidateAssessment.new

    lodge_assessment_use_case = UseCase::LodgeAssessment.new

    check_assessor_belongs_to_scheme_use_case =
      UseCase::CheckAssessorBelongsToScheme.new

    search_addresses_by_address_id_use_case =
      UseCase::SearchAddressesByAddressId.new

    search_addresses_by_postcode_use_case =
      UseCase::SearchAddressesByPostcode.new

    search_addresses_by_street_and_town_use_case =
      UseCase::SearchAddressesByStreetAndTown.new

    validate_and_lodge_assessment_use_case =
      UseCase::ValidateAndLodgeAssessment.new(
        validate_assessment_use_case,
        lodge_assessment_use_case,
        check_assessor_belongs_to_scheme_use_case,
      )

    @objects = {
      lodge_assessment_use_case: lodge_assessment_use_case,
      check_assessor_belongs_to_scheme_use_case:
        check_assessor_belongs_to_scheme_use_case,
      validate_assessment_use_case: validate_assessment_use_case,
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
