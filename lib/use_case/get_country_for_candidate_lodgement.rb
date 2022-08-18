module UseCase
  class GetCountryForCandidateLodgement
    def initialize(
      get_canonical_address_id_use_case:,
      get_country_for_postcode_use_case:,
      address_base_country_gateway:
    )
      @get_canonical_address_id_use_case = get_canonical_address_id_use_case
      @get_country_for_postcode_use_case = get_country_for_postcode_use_case
      @address_base_country_gateway = address_base_country_gateway
    end

    def execute(rrn:, address_id:, postcode:)
      canonical_address_id = @get_canonical_address_id_use_case.execute(rrn:,
                                                                        address_id:)

      if canonical_address_id.start_with?("UPRN-")
        @address_base_country_gateway.lookup_from_uprn canonical_address_id
      else
        @get_country_for_postcode_use_case.execute postcode:
      end
    end
  end
end
