module Gateway
  class BoilerUpgradeSchemeGateway
    DOMESTIC_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
      CEPC
    ].freeze

    def search_by_postcode_and_building_identifier(postcode:, building_identifier:)
      identifier = Helper::AddressSearchHelper.clean_building_identifier building_identifier
      if identifier.match?(/^\d+$/)
        search_by_postcode_and_building_number postcode: postcode, building_number: identifier, assessment_types: ASSESSMENT_TYPES
      else
        search_by_postcode_and_building_name postcode: postcode, building_name: identifier, assessment_types: ASSESSMENT_TYPES
      end
    end

    def search_by_uprn(uprn)
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

      sql = add_type_filter(sql, ASSESSMENT_TYPES)

      do_search(
        sql: sql,
        binds: [
          Helper::AddressSearchHelper.string_attribute("uprn", uprn),
        ],
      )
    end

    def search_by_rrn(rrn)
      sql = <<-SQL
        SELECT
          assessment_id AS epc_rrn,
          type_of_assessment AS report_type,
          date_of_expiry AS expiry_date
        FROM assessments
        WHERE assessment_id = $1
      SQL

      do_search(
        sql: sql,
        binds: [
          Helper::AddressSearchHelper.string_attribute("rrn", rrn),
        ],
      )
    end

  private

    def row_to_domain(row)
      assessment_summary =
        UseCase::AssessmentSummary::Fetch.new.execute row["epc_rrn"]

      return nil if block_given? && !yield(assessment_summary)

      Domain::AssessmentBusDetails.new(
        epc_rrn: row["epc_rrn"],
        report_type: row["report_type"],
        expiry_date: row["expiry_date"],
        cavity_wall_insulation_recommended: has_domestic_recommendation?(type: "B", summary: assessment_summary),
        loft_insulation_recommended: has_domestic_recommendation?(type: "A", summary: assessment_summary),
        secondary_heating: fetch_property_description(node_name: "secondary_heating", summary: assessment_summary),
        address: assessment_summary[:address].slice(
          :address_id,
          :address_line1,
          :address_line2,
          :address_line3,
          :address_line4,
          :town,
          :postcode,
        ).transform_values { |v| v || "" },
        dwelling_type: assessment_summary[:dwelling_type] || assessment_summary[:property_type],
      )
    rescue UseCase::AssessmentSummary::Fetch::AssessmentUnavailable
      nil
    end

    def search_by_postcode_and_building_number(postcode:, building_number:, assessment_types:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date
          FROM assessments AS a
          WHERE 0=0
      SQL

      sql << Helper::AddressSearchHelper.where_postcode_and_number_clause

      sql = add_type_filter(sql, assessment_types)

      do_search(
        sql: sql,
        binds: Helper::AddressSearchHelper.bind_postcode_and_number(postcode, building_number),
      )
    end

    def search_by_postcode_and_building_name(postcode:, building_name:, assessment_types:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date
          FROM assessments AS a
          WHERE 0=0
      SQL
      sql << Helper::AddressSearchHelper.where_postcode_and_name_clause

      sql = add_type_filter(sql, assessment_types)

      do_search(
        sql: sql,
        binds: Helper::AddressSearchHelper.bind_postcode_and_name(postcode, building_name),
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
          Helper::AddressSearchHelper.string_attribute("uprn", uprn),
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

    def add_type_filter(sql, assessment_types)
      list_of_types = assessment_types.map { |n| "'#{n}'" }.join(",")
      sql << <<~SQL_TYPE_OF_ASSESSMENT
        AND type_of_assessment IN(#{list_of_types})
      SQL_TYPE_OF_ASSESSMENT
    end

    def fetch_property_description(node_name:, summary:)
      if summary[:property_summary]
        summary[:property_summary].each do |feature|
          return feature[:description] if feature[:name] == node_name
        end
      end

      nil
    end

    def has_domestic_recommendation?(type:, summary:)
      unless DOMESTIC_TYPES.include? summary[:type_of_assessment]
        return nil
      end

      summary[:recommended_improvements].any? { |improvement| improvement[:improvement_type] == type }
    end
  end
end
