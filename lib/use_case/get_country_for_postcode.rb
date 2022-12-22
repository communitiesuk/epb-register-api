module UseCase
  class GetCountryForPostcode
    WALES_ONLY_POSTCODE_PREFIXES = %w[CF SA LL3 LL4 LL5 LL6 LL7].freeze

    WALES_ONLY_POSTCODE_OUTCODES = %w[CH5
                                      CH6
                                      CH7
                                      CH8
                                      LD1
                                      LD2
                                      LD3
                                      LD4
                                      LD5
                                      LD6
                                      LL15
                                      LL16
                                      LL17
                                      LL18
                                      LL19
                                      LL21
                                      LL22
                                      LL23
                                      LL24
                                      LL25
                                      LL26
                                      LL27
                                      LL28
                                      LL29
                                      NP4
                                      NP8
                                      NP10
                                      NP11
                                      NP12
                                      NP13
                                      NP15
                                      NP18
                                      NP19
                                      NP20
                                      NP22
                                      NP23
                                      NP24
                                      NP26
                                      NP44
                                      SY16
                                      SY17
                                      SY18
                                      SY19
                                      SY20
                                      SY22
                                      SY23
                                      SY24
                                      SY25].freeze

    CROSS_BORDER_ENGLAND_AND_WALES_POSTCODE_OUTCODES =
      %w[CH1
         CH4
         HR2
         HR3
         HR5
         LD7
         LD8
         LL11
         LL12
         LL13
         LL14
         LL20
         NP7
         NP16
         NP25
         SY5
         SY10
         SY15
         SY21].freeze
    IN_WALES_ONLY_REGEX = Regexp.new((WALES_ONLY_POSTCODE_PREFIXES.map { |fragment| "^#{fragment}" } + WALES_ONLY_POSTCODE_OUTCODES.map { |fragment| "(#{fragment}\s)" }).join("|")).freeze
    CROSS_BORDER_ENGLAND_AND_WALES_REGEX = Regexp.new("^#{CROSS_BORDER_ENGLAND_AND_WALES_POSTCODE_OUTCODES.map { |fragment| "(#{fragment}\s)" }.join('|')}").freeze

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
      else
        lookup_for [:E]
      end
    end

  private

    attr_reader :address_base_country_gateway

    def lookup_for(country_codes)
      Domain::CountryLookup.new country_codes:
    end
  end
end
