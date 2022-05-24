module Gateway
  class BoilerUpgradeSchemeGateway
    include Gateway::CommonAddressSearchGateway

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
      identifier = clean_building_identifier building_identifier
      if identifier.match?(/^\d+$/)
        search_by_postcode_and_building_number postcode: postcode, building_number: identifier, assessment_types: ASSESSMENT_TYPES
      else
        search_by_postcode_and_building_name postcode: postcode, building_name: identifier, assessment_types: ASSESSMENT_TYPES
      end
    end

    def search_by_uprn(uprn)
      fetch_by_uprn(uprn, ASSESSMENT_TYPES)
    end

    def search_by_rrn(rrn)
      fetch_by_rrn(rrn)
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

    def clean_building_identifier(building_identifier)
      building_identifier&.delete!("()|:*!\\") || building_identifier
    end
  end
end
