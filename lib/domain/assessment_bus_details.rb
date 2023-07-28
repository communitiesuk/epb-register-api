module Domain
  class AssessmentBusDetails
    DOMESTIC_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    def initialize(
      bus_details:,
      assessment_summary:
    )
      @bus_details = bus_details
      @assessment_summary = assessment_summary
    end

    def to_hash
      {
        epc_rrn: @bus_details["epc_rrn"],
        report_type: @bus_details["report_type"],
        expiry_date: @bus_details["expiry_date"].strftime("%Y-%m-%d"),
        cavity_wall_insulation_recommended: has_domestic_recommendation?(type: "B"),
        loft_insulation_recommended: has_domestic_recommendation?(type: "A"),
        secondary_heating: fetch_property_description(node_name: "secondary_heating"),
        address: @assessment_summary[:address].slice(
          :address_line1,
          :address_line2,
          :address_line3,
          :address_line4,
          :town,
          :postcode,
        ).transform_values { |v| v || "" },
        dwelling_type: fetch_dwelling_type,
        lodgement_date: @assessment_summary[:date_of_registration],
        uprn: strip_uprn,
      }
    end

    def rrn
      @bus_details["epc_rrn"]
    end

  private

    def has_domestic_recommendation?(type:)
      unless DOMESTIC_TYPES.include? @assessment_summary[:type_of_assessment]
        return nil
      end

      @assessment_summary[:recommended_improvements].any? { |improvement| improvement[:improvement_type] == type }
    end

    def fetch_property_description(node_name:)
      if @assessment_summary[:property_summary]
        @assessment_summary[:property_summary].each do |feature|
          return feature[:description] if feature[:name] == node_name && !feature[:description].empty?
        end
      end

      nil
    end

    def fetch_dwelling_type
      if @assessment_summary[:dwelling_type] && !@assessment_summary[:dwelling_type].empty?
        @assessment_summary[:dwelling_type]
      else
        @assessment_summary[:property_type] && !@assessment_summary[:property_type].empty?
        @assessment_summary[:property_type]
      end
    end

    def strip_uprn
      uprn = @bus_details["uprn"]
      uprn.include?("UPRN") ? uprn.sub("UPRN-", "") : nil
    end
  end
end
