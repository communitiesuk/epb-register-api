module Gateway
  class AddressBaseSearchGateway


    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = postcode.delete " "

      sql =
          "SELECT
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            postcode,
            uprn
          FROM address_base
          WHERE
            LOWER(REPLACE(postcode, ' ', '')) = $1"

      binds = [
          ActiveRecord::Relation::QueryAttribute.new(
              "postcode",
              postcode.downcase,
              ActiveRecord::Type::String.new,
              ),
      ]

      ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end
  end
end

