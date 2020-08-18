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

    def search_by_uprn(uprn)
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
            uprn = $1'

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "uprn",
          uprn.to_i.to_s,
          ActiveRecord::Type::String.new,
        ),
      ]

      parse_results ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end

  private

    def parse_results(results)
      results = populate_related_assessments(results)

      results.map(&method(:record_to_address_domain))
    end

    def populate_related_assessments(addresses)
      uprns = {}
      addresses.each_with_index do |address, i|
        uprns["UPRN-" + address["uprn"].rjust(12, "0")] = i
        addresses[i]["existing_assessments"] = []
      end

      if uprns.length > 0
        sql =
          'SELECT
              assessment_id, type_of_assessment, cancelled_at, not_for_issue_at, date_of_expiry, address_id
            FROM assessments
            WHERE
              address_id IN(' +
          uprns.keys.map { |uprn|
            ActiveRecord::Base.connection.quote(uprn)
          }.join(", ") + ")"

        existing_assessments = ActiveRecord::Base.connection.exec_query(sql)

        existing_assessments.each do |row|
          status =
            if row["cancelled_at"].nil?
              if row["not_for_issue_at"].nil?
                if Date.parse(row["date_of_expiry"]) < Date.now
                  "EXPIRED"
                else
                  "ENTERED"
                end
              else
                "NOT_FOR_ISSUE"
              end
            else
              "CANCELLED"
            end

          addresses[uprns[row["address_id"]]]["existing_assessments"].push(
            {
              assessment_id: row["assessment_id"],
              assessment_status: status,
              assessment_type: row["assessment_type"],
            },
          )
        end
      end

      addresses
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
                          existing_assessments: row["existing_assessments"]
    end
  end
end
