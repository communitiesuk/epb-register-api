module Gateway
  class AddressBaseSearchGateway
    def search_by_postcode(postcode, building_name_number, _address_type)
      postcode = postcode.insert(-4, " ") if postcode[-4] != " "
      postcode = postcode.upcase

      sql =
        'SELECT
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            postcode,
            uprn
          FROM address_base
          WHERE
            postcode = $1'

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "postcode",
          postcode,
          ActiveRecord::Type::String.new,
        ),
      ]

      sql << " ORDER BY "

      if building_name_number
        sql <<
          "#{levenshtein('address_line1', '$2')}, #{
            levenshtein('address_line2', '$2')
          }, "

        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "building_name_number",
            building_name_number,
            ActiveRecord::Type::String.new,
          )
      end

      sql << "uprn"

      parse_results ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end

  private

    def parse_results(results)
      results = results.map { |row| record_to_address_domain row }

      results
    end

    def levenshtein(property, bind, permissiveness = nil)
      levenshtein =
        "LEVENSHTEIN(LOWER(#{property}), LOWER(#{
          bind
        }))::decimal / GREATEST(length(#{property}), length(#{bind}))"

      levenshtein << " < #{permissiveness}" if permissiveness

      levenshtein
    end

    def record_to_address_domain(row)
      Domain::Address.new address_id: "UPRN-" + row["uprn"].rjust(12, "0"),
                          line1: row["address_line1"],
                          line2: row["address_line2"].presence,
                          line3: row["address_line3"].presence,
                          line4: row["address_line4"].presence,
                          town: row["town"],
                          postcode: row["postcode"],
                          source: "GAZETTEER",
                          existing_assessments: nil
    end
  end
end
