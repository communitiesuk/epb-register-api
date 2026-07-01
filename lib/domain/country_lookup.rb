module Domain
  ##
  # A lookup object provides information about countries that the lookup parameter
  # is associated with.
  #
  # NB. A lookup can reference multiple countries - there are 115 individual postcodes that contain potentially EPC-able
  # properties in both England and Wales (i.e. the postcode area crosses the border).
  #
  # @example
  #
  #     lookup = gateway.lookup_from_postcode "HR3 6HW"
  #     lookup.match? # true if lookup matches at least one country, false otherwise
  #     lookup.in_england? # true if the parameter knowingly relates to a geographical area within england, false otherwise
  #     lookup.in_wales? # true if parameter relates to area in wales, false otherwise
  #     lookup.on_border? # true if there is more than one country
  #     lookup.country_code # ['E', 'W'] as an example (representing a postcode that covers area in both England and Wales)
  class CountryLookup
    COUNTRIES = {
      E: "england",
      W: "wales",
      S: "scotland",
      N: "northern_ireland",
      L: "channel_islands",
      M: "isle_of_man",
      J: "in_unassigned_location",
    }.freeze

    attr_accessor :country_codes

    def initialize(country_codes:)
      @country_codes = country_codes.map(&:to_sym).sort
    end

    def match?
      !country_codes.empty?
    end

    def on_border?
      country_codes.length > 1
    end

    COUNTRIES.each do |code, name|
      define_method :"in_#{name}?" do
        country_codes.include?(code)
      end
    end
  end
end
