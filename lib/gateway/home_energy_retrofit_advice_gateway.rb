module Gateway
  class HomeEnergyRetrofitAdviceGateway

    def fetch_by_rrn(rrn)
      sql = <<-SQL
        SELECT
          xml,
          schema_type
        FROM assessments_xml ass_xml
          JOIN assessments ass ON ass.assessment_id = ass_xml.assessment_id
        WHERE ass_xml.assessment_id = $1
        AND ass.cancelled_at IS NULL
        AND ass.not_for_issue_at IS NULL
        AND ass.postcode NOT LIKE 'BT%'
        AND ass.type_of_assessment IN ('SAP', 'RdSAP')
      SQL

      binds = [
        string_attribute("rrn", rrn)
      ]

      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      result.first
    end

    private

    def string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
        )
    end

    # def row_to_domain(row)
    #   assessment_summary =
    #     UseCase::AssessmentSummary::Fetch.new.execute row["epc_rrn"]
    #
    #   # return nil if block_given? && !yield(assessment_summary)
    #
    #   Domain::AssessmentBusDetails.new(
    #     epc_rrn: row["epc_rrn"],
    #     report_type: row["report_type"],
    #     expiry_date: row["expiry_date"],
    #     is_latest_assessment_for_address: !assessment_summary['supersupersuper_stuff'],
    #     cavity_wall_insulation_recommended: has_domestic_recommendation?(type: "B", summary: assessment_summary),
    #     loft_insulation_recommended: has_domestic_recommendation?(type: "A", summary: assessment_summary),
    #     secondary_heating: fetch_property_description(node_name: "secondary_heating", summary: assessment_summary),
    #     address: assessment_summary[:address].slice(
    #       :address_id,
    #       :address_line1,
    #       :address_line2,
    #       :address_line3,
    #       :address_line4,
    #       :town,
    #       :postcode,
    #       ).transform_values { |v| v || "" },
    #     dwelling_type: assessment_summary[:dwelling_type] || assessment_summary[:property_type],
    #     )
    # rescue UseCase::AssessmentSummary::Fetch::AssessmentUnavailable
    #   nil
    # end

    # def fetch_property_description(node_name:, summary:)
    #   if summary[:property_summary]
    #     summary[:property_summary].each do |feature|
    #       return feature[:description] if feature[:name] == node_name
    #     end
    #   end
    #
    #   nil
    # end

    # def has_domestic_recommendation?(type:, summary:)
    #   unless DOMESTIC_TYPES.include? summary[:type_of_assessment]
    #     return nil
    #   end
    #
    #   summary[:recommended_improvements].any? { |improvement| improvement[:improvement_type] == type }
    # end
  end
end
