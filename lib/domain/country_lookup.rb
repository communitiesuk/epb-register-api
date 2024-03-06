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

    COUNTRY_IDS = {
      1 => [:E],
      2 => [:W],
      3 => [:N],
      4 => %i[E W],
      5 => [:S],
      6 => %i[E S],
      7 => [:L],
      8 => [:M],
      9 => [:J],
    }.freeze

    UK_COUNTRY_CODES = {
      ENG: 1,
      WLS: 2,
      NIR: 3,
      EAW: 4,
      SCT: 5,
      IOM: 8,
      NR: 9,
    }.freeze

    def initialize(country_codes:)
      @country_codes = country_codes.map(&:to_sym)
    end

    def self.success(country_codes)
      new country_codes:
    end

    def match?
      !country_codes.empty?
    end

    def method_missing(name, *_args)
      in_country = name.match(/^in_(\w+)\?$/)[1]
      if in_country && COUNTRIES.value?(in_country)
        return in_country? in_country
      end

      super
    rescue NoMethodError
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      in_country = method_name.match(/^in_(\w+)\?$/)[1]
      in_country && COUNTRIES.value?(in_country) || super
    end

    def country_codes
      @country_codes.sort
    end

    def country_id
      COUNTRY_IDS.key(country_codes)
    rescue NoMethodError
      nil
    end

    def on_border?
      @country_codes.length > 1
    end

    def uk_country_code(xml_country_code)
      UK_COUNTRY_CODES[xml_country_code.to_sym]
    end

  private

    def in_country?(country_name)
      country_codes.include?(COUNTRIES.key(country_name))
    end
  end
end
