module Gateway
  class PrsDatabaseGateway
    ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    # def search_by_postcode_and_building_identifier(postcode:, building_identifier:)
    #   identifier = Helper::AddressSearchHelper.clean_building_identifier building_identifier
    #   if identifier.match?(/^\d+$/)
    #     search_by_postcode_and_building_number postcode:, building_number: identifier, assessment_types: ASSESSMENT_TYPES
    #   else
    #     search_by_postcode_and_building_name postcode:, building_name: identifier, assessment_types: ASSESSMENT_TYPES
    #   end
    # end

    def search_by_uprn(uprn)
      sql = <<-SQL
      WITH assessment_cte as(
        SELECT a.assessment_id AS epc_rrn,
               a.date_of_expiry AS expiry_date,
               a.date_of_expiry AS expiry_date,
               a.address_line1 AS address_line1,
               a.address_line2 AS address_line2,
               a.address_line3 AS address_line3,
               a.address_line3 AS address_line4,
               a.town AS town,
               a.postcode AS postcode,
               a.current_energy_efficiency_rating AS current_energy_efficiency_rating,
               row_number() over (PARTITION BY address_id ORDER BY date_of_expiry DESC, created_at DESC, date_of_assessment DESC, a.assessment_id DESC) rn
        FROM assessments AS a
        WHERE assessment_id IN (
            SELECT assessment_id FROM assessments_address_id WHERE address_id = $1
          )
        AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
      SQL

      sql = add_type_filter(sql, ASSESSMENT_TYPES)

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
          a.assessment_id AS epc_rrn,
          a.date_of_expiry AS expiry_date,
          a.address_line1 AS address_line1,
          a.address_line2 AS address_line2,
          a.address_line3 AS address_line3,
          a.address_line3 AS address_line4,
          a.town AS town,
          a.postcode AS postcode,
          a.current_energy_efficiency_rating AS current_energy_efficiency_rating
        FROM assessments a
        WHERE a.assessment_id = $1
        AND a.cancelled_at IS NULL
        AND a.not_for_issue_at IS NULL
        AND a.type_of_assessment IN ('RdSAP', 'SAP')
      SQL
      binds =
        [Helper::AddressSearchHelper.string_attribute("rrn", rrn)]

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      return nil if results.count.zero?

      results.first
    end

  # private

    #
    def do_search(sql:, binds:)
      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      return nil if results.count.zero?

      results
    end
    #
    def add_type_filter(sql, assessment_types)
      list_of_types = assessment_types.map { |n| "'#{n}'" }.join(",")
      sql << <<~SQL_TYPE_OF_ASSESSMENT
        AND type_of_assessment IN(#{list_of_types})
      SQL_TYPE_OF_ASSESSMENT
    end
  end
end
