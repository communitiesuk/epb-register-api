module Gateway
  class AddressBaseCountryGateway
    ##
    # @param [String] uprn The UPRN to look up, either in "12345" or "UPRN-000000012345" format
    #
    # @return [Domain::CountryLookup]
    def lookup_from_uprn(uprn)
      do_lookup sql: "SELECT country_code FROM address_base WHERE uprn = $1",
                param: normalise_uprn(uprn)
    end

    ##
    # @param [String] postcode A correctly-formatted postcode to lookup, i.e. "SW1A 1AA" not "sw1a1aa"
    #
    # @return [Domain::CountryLookup]
    def lookup_from_postcode(postcode)
      do_lookup sql: "SELECT DISTINCT country_code FROM address_base WHERE postcode = $1",
                param: postcode
    end

  private

    def do_lookup(sql:, param:)
      Domain::CountryLookup.new country_codes: ActiveRecord::Base.connection.exec_query(
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
  end
end
