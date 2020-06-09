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

      results.map do |row|
        populate_existing_assessments record_to_address_domain row
      end
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

    def populate_existing_assessments(address)
      unless address.is_a? Domain::Address
        raise StandardError, "must be an address domain object"
      end

      sql =
        "
         SELECT all_assessments.assessment_id,
                 all_assessments.assessment_type,
                 CASE WHEN all_assessments.date_of_expiry < CURRENT_DATE THEN 'EXPIRED'
                      ELSE 'ENTERED'
                     END AS assessment_status
          FROM (
              SELECT a.assessment_id,
                 a.type_of_assessment AS assessment_type,
                 a.date_of_expiry
              FROM (
                  WITH RECURSIVE
                  forwards AS (
                    SELECT a.assessment_id, a.address_id FROM assessments a WHERE a.address_id = $1
                    UNION
                    SELECT a_forwards.assessment_id, a_forwards.address_id FROM assessments a_forwards
                    INNER JOIN forwards f ON REPLACE(a_forwards.address_id, 'RRN-', '') = f.assessment_id
                  ),
                  backwards AS (
                    SELECT a.assessment_id, a.address_id FROM assessments a WHERE a.address_id = $1
                    UNION
                    SELECT a_backwards.assessment_id, a_backwards.address_id FROM assessments a_backwards
                    INNER JOIN backwards b ON REPLACE(b.address_id, 'RRN-', '') = a_backwards.assessment_id
                  )
                  SELECT forwards.assessment_id FROM forwards
                  UNION
                  SELECT backwards.assessment_id FROM backwards
              ) existing_assessments
              INNER JOIN assessments a ON existing_assessments.assessment_id = a.assessment_id
              WHERE existing_assessments.assessment_id != REPLACE($1, 'RRN-', '')
              UNION
              SELECT this_assessment.assessment_id,
                     this_assessment.type_of_assessment AS assessment_type,
                     this_assessment.date_of_expiry
              FROM assessments this_assessment
              WHERE this_assessment.assessment_id = REPLACE($1, 'RRN-', '')
          ) as all_assessments
          ORDER BY date_of_expiry DESC"

      results =
        ActiveRecord::Base.connection.exec_query(
          sql,
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "address_id",
              address.address_id,
              ActiveRecord::Type::String.new,
            ),
          ],
        )

      address.existing_assessments = []

      results.each do |result|
        address.existing_assessments <<
          {
            assessmentId: result["assessment_id"],
            assessmentStatus: result["assessment_status"],
            assessmentType: result["assessment_type"],
          }
      end

      address
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
