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

    def common_sql_expression
      <<-SQL
          WITH assessment_cte as(
            SELECT a.assessment_id,
                   a.address_line1,
                   a.address_line2,
                   a.address_line3,
                   a.address_line4,
                   a.town,
                   a.postcode,
                  row_number() over (PARTITION BY aai.address_id ORDER BY date_of_expiry DESC, created_at DESC, a.assessment_id DESC) rn
                  FROM assessments AS a
            JOIN assessments_address_id aai ON a.assessment_id = aai.assessment_id
            WHERE type_of_assessment IN ('SAP', 'RdSAP')
            AND  a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL

      SQL
    end

    def fetch_by_postcode_and_building_number(postcode:, building_number:)
      sql = common_sql_expression
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
            SELECT *
            FROM assessment_cte
            WHERE rn =1
            ORDER BY address_line1
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
      sql = common_sql_expression
      sql << <<-SQL
          AND a.postcode = $1 AND (a.address_line1 ILIKE $2 OR a.address_line2 ILIKE $2))
          SELECT *
            FROM assessment_cte
            WHERE rn =1
             ORDER BY address_line1
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
      details_list = results.map { |result| row_to_domain(result) }
      return nil if details_list.count.zero?

      details_list
    end

    def row_to_domain(row)
      Domain::HomeEnergyAdviceItem.new(
        assessment_id: row["assessment_id"],
        address_line1: row["address_line1"],
        address_line2: row["address_line2"],
        address_line3: row["address_line3"],
        address_line4: row["address_line4"],
        town: row["town"],
        postcode: row["postcode"],
      )
    end
  end
end
