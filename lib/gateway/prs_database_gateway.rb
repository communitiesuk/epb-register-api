module Gateway
  class PrsDatabaseGateway
    def search_by_uprn(uprn)
      sql = <<-SQL
      WITH assessment_cte as(
        SELECT
               a.assessment_id AS epc_rrn,
               a.date_of_expiry AS expiry_date,
               a.address_line1 AS address_line1,
               a.address_line2 AS address_line2,
               a.address_line3 AS address_line3,
               a.address_line3 AS address_line4,
               a.town AS town,
               a.postcode AS postcode,
               a.current_energy_efficiency_rating AS current_energy_efficiency_rating,
               a.type_of_assessment AS type_of_assessment,
               a.assessment_id AS latest_epc_rrn_for_address,
               row_number() over (PARTITION BY address_id ORDER BY date_of_expiry DESC, created_at DESC, date_of_assessment DESC, a.assessment_id DESC) rn
        FROM assessments AS a
        WHERE assessment_id IN (
            SELECT assessment_id FROM assessments_address_id WHERE address_id = $1
          )
      AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
      SQL
      sql << <<-SQL
        )
        SELECT *
            FROM assessment_cte
            WHERE rn =1
      SQL

      do_search(
        sql:,
        binds: [
          Helper::AddressSearchHelper.string_attribute("uprn", uprn),
        ],
      )
    end

    def search_by_rrn(rrn)
      sql = <<-SQL
          SELECT
                a.cancelled_at,
                a.not_for_issue_at,
                a.assessment_id AS epc_rrn,
                a.date_of_expiry AS expiry_date,
                a.address_line1 AS address_line1,
                a.address_line2 AS address_line2,
                a.address_line3 AS address_line3,
                a.address_line3 AS address_line4,
                a.town AS town,
                a.postcode AS postcode,
                a.current_energy_efficiency_rating AS current_energy_efficiency_rating,
                a.type_of_assessment AS type_of_assessment,
          (SELECT a1.assessment_id
            FROM assessments a1
           JOIN assessments_address_id aai1 ON a1.assessment_id = aai1.assessment_id
            WHERE aai1.address_id = aai.address_id ORDER BY a1.date_registered DESC LIMIT 1) as latest_epc_rrn_for_address
          FROM assessments a
          JOIN assessments_address_id aai ON a.assessment_id = aai.assessment_id
          WHERE a.assessment_id = $1
      SQL
      binds =
        [Helper::AddressSearchHelper.string_attribute("rrn", rrn)]

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      return nil if results.count.zero?

      results.first
    end

  private

    def do_search(sql:, binds:)
      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      return nil if results.count.zero?

      results
    end

    def add_type_filter(sql, assessment_types)
      list_of_types = assessment_types.map { |n| "'#{n}'" }.join(",")
      sql << <<~SQL_TYPE_OF_ASSESSMENT
        AND type_of_assessment IN(#{list_of_types})
      SQL_TYPE_OF_ASSESSMENT
    end
  end
end
