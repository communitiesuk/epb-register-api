module UseCase
  # to be used with logic specifically for the back filling of countr_yid in assessment
  class GetCountryForPostcodeBackfill
    IN_WALES_ONLY_REGEX = UseCase::PostcodeData.in_wales_only.freeze
    CROSS_BORDER_ENGLAND_AND_WALES_REGEX = UseCase::PostcodeData.cross_border_eaw_regex.freeze
    IN_SCOTLAND_ONLY_REGEX = UseCase::PostcodeData.in_scotland_only_regex.freeze
    CROSS_BORDER_ENGLAND_AND_SCOTLAND_REGEX = UseCase::PostcodeData.cross_border_england_and_scotland_regex.freeze
    IN_ENGLAND_ONLY_REGEX = UseCase::PostcodeData.in_england_only_regex.freeze

    def initialize(address_base_country_gateway: nil)
      @address_base_country_gateway = address_base_country_gateway || Gateway::AddressBaseCountryGateway.new
    end

    def execute(postcode:)
      case postcode
      when /^BT/
        lookup_for [:N]
      when /^JE/
        lookup_for [:L]
      when /^GY/
        lookup_for [:L]
      when /^IM/
        lookup_for [:M]
      when IN_WALES_ONLY_REGEX
        lookup_for [:W]
      when CROSS_BORDER_ENGLAND_AND_WALES_REGEX
        lookup = address_base_country_gateway.lookup_from_postcode postcode
        lookup.match? ? lookup : lookup_for(%i[E W])
      when IN_SCOTLAND_ONLY_REGEX
        lookup_for [:S]
      when CROSS_BORDER_ENGLAND_AND_SCOTLAND_REGEX
        lookup = address_base_country_gateway.lookup_from_postcode postcode
        lookup.match? ? lookup : lookup_for(%i[E S])
      when IN_ENGLAND_ONLY_REGEX
        lookup_for [:E]
      else
        lookup = address_base_country_gateway.lookup_from_postcode postcode
        lookup.match? ? lookup : lookup_for([])
      end
    end

  private

    attr_reader :address_base_country_gateway

    def lookup_for(country_codes)
      Domain::CountryLookup.new country_codes:
    end
  end
end
