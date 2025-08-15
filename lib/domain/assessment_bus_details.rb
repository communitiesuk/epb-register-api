module Domain
  class AssessmentBusDetails
    DOMESTIC_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    TENURE = {
      "1" => "Owner-occupied",
      "2" => "Rented (social)",
      "3" => "Rented (private)",
      "ND" => "Unknown",
    }.freeze

    def initialize(
      bus_details:,
      assessment_summary:,
      domestic_digest:
    )
      @bus_details = bus_details
      @assessment_summary = assessment_summary
      @domestic_digest = domestic_digest
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
        tenure: TENURE[@assessment_summary[:tenure]],
        inspection_date: @assessment_summary[:date_of_assessment],
        main_fuel_type: !@domestic_digest.nil? ? @domestic_digest[:main_fuel_type] : nil,
        walls_description: fetch_property_description_list(node_name: "wall"),
        total_floor_area: @assessment_summary[:total_floor_area].to_i,
        total_roof_area: @assessment_summary.key?(:total_roof_area) ? @assessment_summary[:total_roof_area].to_i : nil,
        current_energy_efficiency_rating: @assessment_summary[:current_energy_efficiency_rating],
        hot_water_description: fetch_property_description(node_name: "hot_water"),
        lzc_energy_sources: !@domestic_digest.nil? ? @domestic_digest[:lzc_energy_sources] : nil,
        main_heating_description: !@domestic_digest.nil? && !@domestic_digest[:main_heating_category].nil? && !@domestic_digest[:main_heating_category].empty? ? @domestic_digest[:main_heating_category] : nil,
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

    def fetch_property_description_list(node_name:)
      if @assessment_summary[:property_summary]
        @assessment_summary[:property_summary]
          .select { |feature| [node_name, "#{node_name}s"].include?(feature[:name]) } # descriptions in property summary can be called "wall" or "walls", or "window" or "windows" depending on whether SAP or RdSAP due to slight schema divergence here
          .map { |feature| feature[:description] }
      end
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
