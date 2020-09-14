module ViewModel
  class RdSapWrapper
    TYPE_OF_ASSESSMENT = "RD_SAP".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "RdSAP-Schema-20.0.0"
        @view_model = ViewModel::RdSapSchema200::CommonSchema.new xml
      when "RdSAP-Schema-19.0"
        @view_model = ViewModel::RdSapSchema190::CommonSchema.new xml
      when "RdSAP-Schema-18.0"
        @view_model = ViewModel::RdSapSchema180::CommonSchema.new xml
      when "RdSAP-Schema-17.1"
        @view_model = ViewModel::RdSapSchema171::CommonSchema.new xml
      when "RdSAP-Schema-17.0"
        @view_model = ViewModel::RdSapSchema170::CommonSchema.new xml
      when "RdSAP-Schema-NI-20.0.0"
        @view_model = ViewModel::RdSapSchemaNi200::CommonSchema.new xml
      when "RdSAP-Schema-NI-19.0"
        @view_model = ViewModel::RdSapSchemaNi190::CommonSchema.new xml
      when "RdSAP-Schema-NI-18.0"
        @view_model = ViewModel::RdSapSchemaNi180::CommonSchema.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        "g"
      when 21..38
        "f"
      when 39..54
        "e"
      when 55..68
        "d"
      when 69..80
        "c"
      when 81..91
        "b"
      else
        "a"
      end
    end

    def type
      :RdSAP
    end

    def to_hash
      estimated_energy_cost =
        Helper::EstimatedCostPotentialSavingHelper.new.estimated_cost(
          @view_model.heating_cost_current,
          @view_model.hot_water_cost_current,
          @view_model.lighting_cost_current,
        )

      {
        type_of_assessment: "RdSAP",
        assessment_id: @view_model.assessment_id,
        date_of_expiry: @view_model.date_of_expiry,
        date_of_assessment: @view_model.date_of_assessment,
        date_of_registration: @view_model.date_of_registration,
        date_registered: @view_model.date_of_registration,
        address_line1: @view_model.address_line1,
        address_line2: @view_model.address_line2,
        address_line3: @view_model.address_line3,
        address_line4: @view_model.address_line4,
        town: @view_model.town,
        postcode: @view_model.postcode,
        address: {
          address_id: @view_model.address_id,
          address_line1: @view_model.address_line1,
          address_line2: @view_model.address_line2,
          address_line3: @view_model.address_line3,
          address_line4: @view_model.address_line4,
          town: @view_model.town,
          postcode: @view_model.postcode,
        },
        assessor: {
          scheme_assessor_id: @view_model.scheme_assessor_id,
          name: @view_model.assessor_name,
          contact_details: {
            email: @view_model.assessor_email,
            telephone: @view_model.assessor_telephone,
          },
        },
        current_carbon_emission: @view_model.current_carbon_emission,
        current_energy_efficiency_band:
          get_energy_rating_band(@view_model.current_energy_rating),
        current_energy_efficiency_rating: @view_model.current_energy_rating,
        dwelling_type: @view_model.dwelling_type,
        estimated_energy_cost: estimated_energy_cost,
        heat_demand: {
          current_space_heating_demand:
            @view_model.current_space_heating_demand,
          current_water_heating_demand:
            @view_model.current_water_heating_demand,
          impact_of_cavity_insulation: @view_model.impact_of_cavity_insulation,
          impact_of_loft_insulation: @view_model.impact_of_loft_insulation,
          impact_of_solid_wall_insulation:
            @view_model.impact_of_solid_wall_insulation,
        },
        heating_cost_current: @view_model.heating_cost_current,
        heating_cost_potential: @view_model.heating_cost_potential,
        hot_water_cost_current: @view_model.hot_water_cost_current,
        hot_water_cost_potential: @view_model.hot_water_cost_potential,
        lighting_cost_current: @view_model.lighting_cost_current,
        lighting_cost_potential: @view_model.lighting_cost_potential,
        potential_carbon_emission: @view_model.potential_carbon_emission,
        potential_energy_efficiency_band:
          get_energy_rating_band(@view_model.potential_energy_rating),
        potential_energy_efficiency_rating: @view_model.potential_energy_rating,
        potential_energy_saving:
          Helper::EstimatedCostPotentialSavingHelper.new.potential_saving(
            @view_model.heating_cost_potential,
            @view_model.hot_water_cost_potential,
            @view_model.lighting_cost_potential,
            estimated_energy_cost,
          ),
        property_age_band: @view_model.property_age_band,
        property_summary: @view_model.property_summary,
        recommended_improvements:
          @view_model.improvements.map do |improvement|
            improvement[:energy_performance_band_improvement] =
              get_energy_rating_band(
                improvement[:energy_performance_rating_improvement],
              )
            improvement
          end,
        related_party_disclosure_number:
          @view_model.related_party_disclosure_number,
        related_party_disclosure_text:
          @view_model.related_party_disclosure_text,
        tenure: @view_model.tenure,
        total_floor_area: @view_model.total_floor_area,
        opt_out: false,
        status: @view_model.status,
      }
    end

    def get_view_model
      @view_model
    end
  end
end
