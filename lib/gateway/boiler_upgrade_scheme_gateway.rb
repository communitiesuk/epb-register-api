module Gateway
  class BoilerUpgradeSchemeGateway
    ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
      CEPC
    ].freeze

    def search_by_postcode_and_building_identifier(postcode:, building_identifier:)
      identifier = Helper::AddressSearchHelper.clean_building_identifier building_identifier
      if identifier.match?(/^\d+$/)
        search_by_postcode_and_building_number postcode:, building_number: identifier, assessment_types: ASSESSMENT_TYPES
      else
        search_by_postcode_and_building_name postcode:, building_name: identifier, assessment_types: ASSESSMENT_TYPES
      end
    end

    def search_by_uprn(uprn)
      sql = <<-SQL
      WITH assessment_cte as(
        SELECT a.assessment_id AS epc_rrn,
               a.type_of_assessment AS report_type,
               a.date_of_expiry AS expiry_date,
               '#{uprn}' AS uprn,
               row_number() over (PARTITION BY aai.address_id ORDER BY date_of_expiry DESC, created_at DESC, date_of_assessment DESC, a.assessment_id DESC) rn
        FROM assessments AS a
        JOIN assessments_address_id aai on a.assessment_id = aai.assessment_id
        WHERE a.assessment_id IN (
            SELECT assessment_id FROM assessments_address_id WHERE address_id = $1
          )
        AND a.opt_out = FALSE AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
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
          a.type_of_assessment AS report_type,
          a.date_of_expiry AS expiry_date,
          aa.address_id AS uprn
        FROM assessments a
        JOIN assessments_address_id aa ON a.assessment_id = aa.assessment_id
        WHERE a.assessment_id = $1
      SQL
      binds = [Helper::AddressSearchHelper.string_attribute("rrn", rrn)]

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      return nil if results.count.zero?

      results.first
    end

  private

    def search_by_postcode_and_building_number(postcode:, building_number:, assessment_types:)
      sql = <<-SQL
        WITH assessment_cte as(
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date,
            aa.address_id AS uprn,
            row_number() over (PARTITION BY aa.address_id ORDER BY date_of_expiry DESC, created_at DESC, date_of_assessment DESC, a.assessment_id DESC) rn
          FROM assessments AS a
          JOIN assessments_address_id aa ON a.assessment_id = aa.assessment_id
          WHERE
          a.opt_out = FALSE
          AND a.cancelled_at IS NULL
            AND a.not_for_issue_at IS NULL
      SQL

      sql << Helper::AddressSearchHelper.where_postcode_clause
      sql << Helper::AddressSearchHelper.where_number_clause
      sql = add_type_filter(sql, assessment_types)

      sql << <<-SQL
        )
        SELECT *
            FROM assessment_cte
            WHERE rn =1
      SQL

      do_search(
        sql:,
        binds: Helper::AddressSearchHelper.bind_postcode_and_number(postcode, building_number),
      )
    end

    def search_by_postcode_and_building_name(postcode:, building_name:, assessment_types:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date,
            aa.address_id AS uprn
          FROM assessments AS a
          JOIN assessments_address_id aa ON a.assessment_id = aa.assessment_id
          WHERE
          a.opt_out = FALSE
          AND a.cancelled_at IS NULL
            AND a.not_for_issue_at IS NULL
      SQL
      sql << Helper::AddressSearchHelper.where_postcode_clause
      sql << Helper::AddressSearchHelper.where_name_clause
      sql = add_type_filter(sql, assessment_types)

      do_search(
        sql:,
        binds: Helper::AddressSearchHelper.bind_postcode_and_name(postcode, building_name),
      )
    end

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
