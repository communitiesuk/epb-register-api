module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = { DOMESTIC: %w[SAP RdSAP], COMMERCIAL: %w[CEPC] }.freeze
    STREET_PERMISSIVENESS = "0.35".freeze
    TOWN_PERMISSIVENESS = "0.3".freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = postcode.delete " "
      sql =
        "SELECT
            assessment_id,
            date_of_expiry,
            type_of_assessment,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            postcode
          FROM assessments
          WHERE REPLACE(postcode, ' ', '') = $1"

      sql <<
        ' AND date_of_expiry = (
            SELECT max(date_of_expiry)
            FROM assessments AS reports
            WHERE assessments.address_line1 = reports.address_line1
               OR assessments.address_line2 = reports.address_line2
          )'

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "postcode",
          postcode,
          ActiveRecord::Type::String.new,
        ),
      ]

      if address_type
        types = ADDRESS_TYPES[address_type.to_sym].map { |type| "'#{type}'" }

        sql << " AND type_of_assessment IN (#{types.join(', ')})"
      end

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

      sql << "assessment_id, date_of_expiry DESC"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      results.map { |row| record_to_address_domain row }
    end

    def search_by_rrn(rrn)
      results =
        ActiveRecord::Base.connection.exec_query(
          'SELECT
           assessment_id,
           date_of_expiry,
           type_of_assessment,
           address_line1,
           address_line2,
           address_line3,
           address_line4,
           town,
           postcode
         FROM assessments
         WHERE assessment_id = $1',
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "rrn",
              rrn,
              ActiveRecord::Type::String.new,
            ),
          ],
        )

      results.map { |row| record_to_address_domain row }
    end

    def search_by_street_and_town(street, town, address_type)
      sql =
        "SELECT
          assessment_id,
          date_of_expiry,
          type_of_assessment,
          address_line1,
          address_line2,
          address_line3,
          address_line4,
          town,
          postcode
        FROM assessments
        WHERE (#{
          levenshtein('address_line1', '$1', STREET_PERMISSIVENESS)
        } OR #{
          levenshtein('address_line2', '$1', STREET_PERMISSIVENESS)
        })
        AND (#{levenshtein('town', '$2', TOWN_PERMISSIVENESS)} OR #{
          levenshtein('address_line2', '$2', TOWN_PERMISSIVENESS)
        })"

      sql <<
        ' AND date_of_expiry = (
          SELECT max(date_of_expiry)
          FROM assessments AS reports
          WHERE (assessments.address_line1 = reports.address_line1
             OR assessments.address_line2 = reports.address_line2)
             AND assessments.type_of_assessment = reports.type_of_assessment
        )'

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          street,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          town,
          ActiveRecord::Type::String.new,
        ),
      ]

      if address_type
        types = ADDRESS_TYPES[address_type.to_sym].map { |type| "'#{type}'" }

        sql << " AND type_of_assessment IN (#{types.join(', ')})"
      end

      sql <<
        " ORDER BY
                #{
          levenshtein('address_line1', '$1')
        },
                #{
          levenshtein('town', '$2')
        },
                address_line1,
                assessment_id,
                date_of_expiry DESC"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      results.map { |row| record_to_address_domain row }
    end

  private

    def levenshtein(property, bind, permissiveness = nil)
      levenshtein =
        "LEVENSHTEIN(LOWER(#{property}), LOWER(#{
          bind
        }))::decimal / GREATEST(length(#{property}), length(#{bind}))"

      levenshtein << " < #{permissiveness}" if permissiveness

      levenshtein
    end

    def record_to_address_domain(row)
      assessment_status =
        row["date_of_expiry"] < Time.now ? "EXPIRED" : "ENTERED"

      Domain::Address.new address_id: "RRN-#{row['assessment_id']}",
                          line1: row["address_line1"],
                          line2: row["address_line2"].presence,
                          line3: row["address_line3"].presence,
                          line4: row["address_line4"].presence,
                          town: row["town"],
                          postcode: row["postcode"],
                          source: "PREVIOUS_ASSESSMENT",
                          existing_assessments: [
                            assessmentId: row["assessment_id"],
                            assessmentStatus: assessment_status,
                            assessmentType: row["type_of_assessment"],
                          ]
    end
  end
end
