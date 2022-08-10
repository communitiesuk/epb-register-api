module Gateway
  class AddressBaseCountryGateway
    def lookup_from_uprn(uprn)
      do_lookup sql: "SELECT country_code FROM address_base WHERE uprn = $1",
                param: normalise_uprn(uprn)
    end

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
