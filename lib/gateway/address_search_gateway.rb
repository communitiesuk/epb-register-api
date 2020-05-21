module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = { DOMESTIC: %w[SAP RdSAP] }.freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = postcode.delete " "
      sql =
        "SELECT
            assessment_id,
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

      if building_name_number
        sql << " AND address_line1 LIKE $2 OR address_line2 LIKE $2"
        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "building_name_number",
            building_name_number + "%",
            ActiveRecord::Type::String.new,
          )
      end

      if address_type
        types = ADDRESS_TYPES[address_type.to_sym].map { |type| "'#{type}'" }

        sql << " AND type_of_assessment IN (#{types.join(', ')})"
      end

      sql << " ORDER BY address_line1"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      results.map { |row| record_to_address_domain row }
    end

    def search_by_rrn(rrn)
      results =
        ActiveRecord::Base.connection.exec_query(
          'SELECT
           assessment_id,
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
        'SELECT
      assessment_id,
          address_line1,
          address_line2,
          address_line3,
          address_line4,
          town,
          postcode
      FROM assessments
      WHERE address_line1 LIKE $1
      AND town = $2'

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%#{street}%",
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

      sql << " ORDER BY address_line1"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds

      results.map { |row| record_to_address_domain row }
    end

  private

    def record_to_address_domain(row)
      Domain::Address.new building_reference_number:
                            "RRN-#{row['assessment_id']}",
                          line1: row["address_line1"],
                          line2: row["address_line2"],
                          line3: row["address_line3"],
                          town: row["town"],
                          postcode: row["postcode"]
    end
  end
end
