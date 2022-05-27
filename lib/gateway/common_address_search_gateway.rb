module Gateway
  module CommonAddressSearchGateway
    def search_by_postcode_and_building_number(postcode:, building_number:, assessment_types:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date
          FROM assessments AS a
          WHERE a.postcode = $1 AND
            (
              a.address_line1 ~ $2
              OR a.address_line2 ~ $2
              OR a.address_line1 ~ $3
              OR a.address_line2 ~ $3
              OR a.address_line1 ~ $4
              OR a.address_line2 ~ $4
              OR a.address_line1 = $5
              OR a.address_line2 = $5
            )
      SQL

      sql = add_type_filter(sql, assessment_types)

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

    def search_by_postcode_and_building_name(postcode:, building_name:, assessment_types:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date
          FROM assessments AS a
          WHERE a.postcode = $1 AND (a.address_line1 ILIKE $2 OR a.address_line2 ILIKE $2)

      SQL

      sql = add_type_filter(sql, assessment_types)

      do_search(
        sql: sql,
        binds: [
          string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
          string_attribute("building_name", "%#{building_name}%"),
        ],
      )
    end

    def fetch_by_uprn(uprn, assessment_types)
      sql = <<-SQL
        SELECT
          a.assessment_id AS epc_rrn,
          a.type_of_assessment AS report_type,
          a.date_of_expiry AS expiry_date
        FROM assessments AS a
        WHERE assessment_id IN (
          SELECT assessment_id FROM assessments_address_id WHERE address_id = $1
        )
      SQL

      sql = add_type_filter(sql, assessment_types)

      do_search(
        sql: sql,
        binds: [
          string_attribute("uprn", uprn),
        ],
      )
    end

    def do_search(sql:, binds:)
      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      details_list = results.map { |result| row_to_domain(result) { |summary| !summary[:superseded_by] } }.compact

      case details_list.count
      when 0
        nil
      when 1
        details_list.first
      else
        Domain::AssessmentReferenceList.new(*details_list.map(&:rrn))
      end
    end

    def string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end

    def add_type_filter(sql, assessment_types)
      list_of_types = assessment_types.map { |n| "'#{n}'" }.join(",")
      sql << <<~SQL_TYPE_OF_ASSESSMENT
        AND type_of_assessment IN(#{list_of_types})
      SQL_TYPE_OF_ASSESSMENT
    end
  end
end
