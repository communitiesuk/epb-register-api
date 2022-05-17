module Gateway
  class BoilerUpgradeSchemeGateway
    DOMESTIC_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    def search_by_postcode_and_building_identifier(postcode:, building_identifier:)
      sql = <<-SQL
        SELECT
            a.assessment_id AS epc_rrn,
            a.type_of_assessment AS report_type,
            a.date_of_expiry AS expiry_date
          FROM assessments AS a
          WHERE a.postcode = $1 AND (a.address_line1 LIKE $2 OR a.address_line2 LIKE $2)
          AND a.type_of_assessment IN ('RdSAP', 'SAP', 'CEPC')
      SQL

      do_search(
        sql: sql,
        binds: [
          string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
          string_attribute("building_identifier", "#{clean_building_identifier building_identifier}%"),
        ],
      )
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

      do_search(
        sql: sql,
        binds: [
          string_attribute("uprn", uprn),
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
          string_attribute("rrn", rrn),
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

    def string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end

    def clean_building_identifier(building_identifier)
      building_identifier&.delete!("()|:*!\\") || building_identifier
    end
  end
end
