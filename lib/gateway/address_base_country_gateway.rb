module Gateway
  class AddressBaseCountryGateway
    ##
    # @param [String] uprn The UPRN to look up, either in "12345" or "UPRN-000000012345" format
    #
    # @return [Lookup]
    def lookup_from_uprn(uprn)
      do_lookup sql: "SELECT country_code FROM address_base WHERE uprn = $1",
                param: normalise_uprn(uprn)
    end

    ##
    # @param [String] postcode A correctly-formatted postcode to lookup, i.e. "SW1A 1AA" not "sw1a1aa"
    #
    # @return [Lookup]
    def lookup_from_postcode(postcode)
      do_lookup sql: "SELECT DISTINCT country_code FROM address_base WHERE postcode = $1",
                param: postcode
    end

  private

    def do_lookup(sql:, param:)
      Lookup.new country_codes: ActiveRecord::Base.connection.exec_query(
        sql,
        "sql",
        [
          ActiveRecord::Relation::QueryAttribute.new(
            "param",
            param,
            ActiveRecord::Type::String.new,
          ),
        ],
      ).map { |row| row["country_code"] }
    end

    def normalise_uprn(uprn)
      uprn.match(/^(UPRN-0*)?(\d+)$/)[2]
    end

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
    class Lookup
      COUNTRIES = {
        E: "england",
        W: "wales",
        S: "scotland",
        N: "northern_ireland",
        L: "channel_islands",
        M: "isle_of_man",
        J: "in_assigned_location",
      }.freeze

      attr_reader :country_codes

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

    private

      def in_country?(country_name)
        country_codes.include?(COUNTRIES.key(country_name))
      end
    end
  end
end
