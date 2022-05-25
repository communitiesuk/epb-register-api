module Gateway
  class HomeEnergyAdviceGateway
    def fetch_by_address(postcode:, building_identifier:)
      identifier = clean_building_identifier building_identifier
      if identifier.match?(/^\d+$/)
        fetch_by_postcode_and_building_number postcode: postcode, building_number: identifier
      else
        fetch_by_postcode_and_building_name postcode: postcode, building_name: identifier
      end
    end

  private

    def cte_sql_expression
      <<-SQL
          WITH assessment_cte as(
            SELECT a.assessment_id,
                   a.address_line1,
                  row_number() over (PARTITION BY aai.address_id ORDER BY date_of_expiry DESC, date_registered DESC, a.assessment_id DESC) rn
                  FROM assessments AS a
            JOIN assessments_address_id aai ON a.assessment_id = aai.assessment_id
            WHERE type_of_assessment IN ('SAP', 'RdSAP')
      SQL
    end

    def fetch_by_postcode_and_building_number(postcode:, building_number:)
      sql = cte_sql_expression
      sql << <<-SQL
            AND
                  a.postcode = $1 AND
            (
              a.address_line1 ~ $2
              OR a.address_line2 ~ $2
              OR a.address_line1 ~ $3
              OR a.address_line2 ~ $3
              OR a.address_line1 ~ $4
              OR a.address_line2 ~ $4
              OR a.address_line1 = $5
              OR a.address_line2 = $5
            ))
            SELECT assessment_id,
                   address_line1
            FROM assessment_cte
            WHERE rn =1
      SQL

      do_search(
        sql: sql,
        binds: [
          string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
          string_attribute("number_in_middle", sprintf('\D+%s\D+', building_number)),
          string_attribute("number_at_start", sprintf('^%s\D+', building_number)),
          string_attribute("number_at_end", sprintf('\D+%s$', building_number)),
          string_attribute("number_exact", building_number),
        ],
      )
    end

    def fetch_by_postcode_and_building_name(postcode:, building_name:)
      sql = cte_sql_expression
      sql << <<-SQL
          AND a.postcode = $1 AND (a.address_line1 ILIKE $2 OR a.address_line2 ILIKE $2))
          SELECT assessment_id,
                   address_line1
            FROM assessment_cte
            WHERE rn =1
      SQL

      do_search(
        sql: sql,
        binds: [
          string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
          string_attribute("building_name", "%#{building_name}%"),
        ],
      )
    end

    def clean_building_identifier(building_identifier)
      building_identifier&.delete!("()|:*!\\") || building_identifier
    end

    def string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end

    def do_search(sql:, binds:)
      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      results.map(&:symbolize_keys)
    end
  end
end
