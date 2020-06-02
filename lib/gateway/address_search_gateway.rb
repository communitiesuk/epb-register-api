module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = { DOMESTIC: %w[SAP RdSAP], COMMERCIAL: %w[CEPC] }.freeze

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

      sql << "assessment_id"

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
          levenshtein('address_line1', '$1', '0.5')
        } OR #{levenshtein('address_line2', '$1', '0.5')})
        AND (#{
          levenshtein('town', '$2', '0.5')
        } OR #{levenshtein('address_line2', '$2', '0.5')})"

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%#{street}%",
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          "%#{town}%",
          ActiveRecord::Type::String.new,
        ),
      ]

      if address_type
        types = ADDRESS_TYPES[address_type.to_sym].map { |type| "'#{type}'" }

        sql << " AND type_of_assessment IN (#{types.join(', ')})"
      end

      sql << " ORDER BY address_line1, assessment_id"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      results.map { |row| record_to_address_domain row }
    end

  private

    def levenshtein(property, bind, match_threshold = nil)
      if match_threshold
        "LEVENSHTEIN(#{property}, #{bind})::decimal / GREATEST(length(#{
          property
        }), length(#{bind})) < #{match_threshold}"
      else
        "LEVENSHTEIN(#{property}, #{bind})::decimal / GREATEST(length(#{
          property
        }), length(#{bind}))"
      end
    end

    def record_to_address_domain(row)
      assessment_status =
        row["date_of_expiry"] < Time.now ? "EXPIRED" : "ENTERED"

      Domain::Address.new building_reference_number:
                            "RRN-#{row['assessment_id']}",
                          line1: row["address_line1"],
                          line2: row["address_line2"].presence,
                          line3: row["address_line3"].presence,
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
