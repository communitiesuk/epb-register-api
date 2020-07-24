module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = {
      DOMESTIC: %w[SAP RdSAP], COMMERCIAL: %w[DEC DEC-RR CEPC CEPC-RR ACIR ACIC]
    }.freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = postcode.downcase.delete " "
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
          WHERE
            cancelled_at IS NULL
          AND not_for_issue_at IS NULL
          AND LOWER(REPLACE(postcode, ' ', '')) = $1"

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
          "#{
            Helper::LevenshteinSqlHelper.levenshtein('address_line1', '$2')
          }, #{
            Helper::LevenshteinSqlHelper.levenshtein('address_line2', '$2')
          }, "

        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "building_name_number",
            building_name_number,
            ActiveRecord::Type::String.new,
          )
      end

      sql << "assessment_id"

      parse_results ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end

    def search_by_rrn(rrn)
      parse_results ActiveRecord::Base.connection.exec_query(
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
         WHERE
           cancelled_at IS NULL
         AND not_for_issue_at IS NULL
         AND assessment_id = $1',
        "SQL",
        [
          ActiveRecord::Relation::QueryAttribute.new(
            "rrn",
            rrn,
            ActiveRecord::Type::String.new,
          ),
        ],
      )
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
        WHERE
          cancelled_at IS NULL
        AND not_for_issue_at IS NULL
        AND (#{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line1',
            '$1',
            Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
          )
        } OR #{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line2',
            '$1',
            Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
          )
        } OR #{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line3',
            '$1',
            Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
          )
        })
        AND (#{
          Helper::LevenshteinSqlHelper.levenshtein(
            'town',
            '$2',
            Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
          )
        } OR #{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line2',
            '$2',
            Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
          )
        } OR #{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line3',
            '$2',
            Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
          )
        } OR #{
          Helper::LevenshteinSqlHelper.levenshtein(
            'address_line4',
            '$2',
            Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
          )
        })"

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
          Helper::LevenshteinSqlHelper.levenshtein('address_line1', '$1')
        },
                #{Helper::LevenshteinSqlHelper.levenshtein('town', '$2')},
                address_line1,
                assessment_id"

      parse_results ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end

  private

    def parse_results(results)
      results = results.map { |row| record_to_address_domain row }

      results =
        results.each_with_object([]) do |address, output|
          address_in_output =
            output.map(&:address_id).include? address.address_id

          unless address_in_output
            output.dup.each do |stored_address|
              existing_assessments =
                stored_address.existing_assessments.map { |a| a[:assessmentId] }

              if existing_assessments.include? address.address_id.remove "RRN-"
                address_in_output = true
              end
            end
          end

          unless address_in_output
            output << populate_existing_assessments(address)
          end
        end

      results.uniq(&:address_id)
    end

    def populate_existing_assessments(address)
      unless address.is_a? Domain::Address
        raise StandardError, "must be an address domain object"
      end

      sql = <<-SQL
        SELECT all_assessments.assessment_id,
               all_assessments.assessment_type,
               CASE WHEN all_assessments.cancelled_at IS NOT NULL THEN 'CANCELLED'
                    WHEN all_assessments.not_for_issue_at IS NOT NULL THEN 'NOT_FOR_ISSUE'
                    WHEN all_assessments.date_of_expiry < CURRENT_DATE THEN 'EXPIRED'
                    ELSE 'ENTERED'
                   END AS assessment_status
        FROM (
            SELECT a.assessment_id,
               a.type_of_assessment AS assessment_type,
               a.date_of_expiry,
               a.cancelled_at,
               a.not_for_issue_at
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
                   this_assessment.date_of_expiry,
                   this_assessment.cancelled_at,
                   this_assessment.not_for_issue_at
            FROM assessments this_assessment
            WHERE this_assessment.assessment_id = REPLACE($1, 'RRN-', '')
        ) as all_assessments
        ORDER BY date_of_expiry DESC
      SQL

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
      address.address_id = "RRN-#{results[0]['assessment_id']}"

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
                            assessmentStatus: row["assessment_status"],
                            assessmentType: row["assessment_type"],
                          ]
    end
  end
end
