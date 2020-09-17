module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = {
      DOMESTIC: %w[SAP RdSAP],
      COMMERCIAL: %w[DEC DEC-RR CEPC CEPC-RR AC-REPORT AC-CERT],
    }.freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = postcode.insert(-4, " ") if postcode[-4] != " "

      sql = <<-SQL
        SELECT
            assessment_id,
            date_of_expiry,
            date_registered,
            type_of_assessment,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            postcode,
            address_id,
            type_of_assessment
          FROM assessments
          WHERE
            cancelled_at IS NULL
          AND not_for_issue_at IS NULL
          AND postcode = $1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "postcode",
          postcode.upcase,
          ActiveRecord::Type::String.new,
        ),
      ]

      sql << " ORDER BY "

      if building_name_number
        sql <<
          "LEAST(
            #{Helper::LevenshteinSqlHelper.levenshtein('address_line1', '$2')},
            #{Helper::LevenshteinSqlHelper.levenshtein('address_line2', '$2')}
          ), "

        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "building_name_number",
            building_name_number,
            ActiveRecord::Type::String.new,
          )
      end

      sql << "assessment_id"

      parse_results(
        ActiveRecord::Base.connection.exec_query(sql, "SQL", binds),
        address_type,
      )
    end

    def search_by_rrn(rrn)
      parse_results(
        ActiveRecord::Base.connection.exec_query(
          "SELECT
             assessment_id,
             date_of_expiry,
             date_registered,
             type_of_assessment,
             address_line1,
             address_line2,
             address_line3,
             address_line4,
             town,
             postcode,
             address_id,
             type_of_assessment
           FROM assessments
           WHERE
             cancelled_at IS NULL
           AND not_for_issue_at IS NULL
           AND (assessment_id = $1 OR address_id = CONCAT('RRN-', $1))
           ORDER BY assessment_id",
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "rrn",
              rrn,
              ActiveRecord::Type::String.new,
            ),
          ],
        ),
        nil,
      )
    end

    def search_by_street_and_town(street, town, address_type)
      sql =
        "SELECT
          assessment_id,
          date_of_expiry,
          date_registered,
          type_of_assessment,
          address_line1,
          address_line2,
          address_line3,
          address_line4,
          town,
          postcode,
          address_id,
          type_of_assessment
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

      sql <<
        " ORDER BY
                LEAST(
                  #{
          Helper::LevenshteinSqlHelper.levenshtein('address_line1', '$1')
        },
                  #{
          Helper::LevenshteinSqlHelper.levenshtein('address_line2', '$1')
        }
                ),
                #{Helper::LevenshteinSqlHelper.levenshtein('town', '$2')},
                address_line1,
                assessment_id"

      parse_results(
        ActiveRecord::Base.connection.exec_query(sql, "SQL", binds),
        address_type,
      )
    end

  private

    def parse_results(results, address_type)
      address_id = {}

      results.enum_for(:each_with_index).map do |res, i|
        unless address_id.key?(res["address_id"])
          address_id[res["address_id"]] = []
        end
        address_id[res["address_id"]].push(i)
      end

      results.map { |result|
        result["existing_assessments"] = []

        skip_because_newer = false

        (
          address_id[result["address_id"]] +
            address_id["RRN-" + result["assessment_id"]].to_a
        ).uniq.each do |sibling|
          sib_data = results[sibling]

          result["existing_assessments"].push(
            {
              assessmentId: sib_data["assessment_id"],
              assessmentStatus: update_expiry_and_status(sib_data),
              assessmentType: sib_data["type_of_assessment"],
            },
          )

          if !address_type.nil? &&
              !ADDRESS_TYPES[address_type.to_sym].include?(
                sib_data["type_of_assessment"],
              )
            if sib_data["date_of_expiry"] < result["date_of_expiry"]
              result["assessment_id"] = sib_data["assessment_id"]
            end
          end

          next unless sib_data["assessment_id"] != result["assessment_id"]

          if sib_data["date_of_expiry"] <= result["date_of_expiry"]
            skip_because_newer = true
          end
        end

        next if skip_because_newer

        if !address_type.nil? &&
            !ADDRESS_TYPES[address_type.to_sym].include?(
              result["type_of_assessment"],
            )
          next
        end

        result["assessment_status"] = update_expiry_and_status(result)

        record_to_address_domain(result)
      }.compact
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
                          existing_assessments: row["existing_assessments"]
    end

    # EPBR-511: Needs to be removed after fixing the database data
    def update_expiry_and_status(result)
      if result["type_of_assessment"] == "RdSAP" || result["type_of_assessment"] == "SAP"
        result["date_of_expiry"] = result["date_registered"].next_year(10)
      end

      # In the previous SQL queries we only select NULL cancelled_at and not_for_issue_at
      expiry_helper = Gateway::AssessmentExpiryHelper.new(result["cancelled_at"], result["not_for_issue_at"], result["date_of_expiry"])
      expiry_helper.assessment_status
    end

  end
end
