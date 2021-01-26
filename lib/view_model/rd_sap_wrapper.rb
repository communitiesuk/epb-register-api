module ViewModel
  class RdSapWrapper
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
      when "RdSAP-Schema-NI-17.4"
        @view_model = ViewModel::RdSapSchemaNi174::CommonSchema.new xml
      when "RdSAP-Schema-NI-17.3"
        @view_model = ViewModel::RdSapSchemaNi173::CommonSchema.new xml
      else
        raise ArgumentError, "Unsupported schema type"
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
          Helper::EnergyBandCalculator.domestic(@view_model.current_energy_rating),
        current_energy_efficiency_rating: @view_model.current_energy_rating,
        dwelling_type: @view_model.dwelling_type,
        estimated_energy_cost: estimated_energy_cost,
        main_fuel_type: @view_model.main_fuel_type,
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
          Helper::EnergyBandCalculator.domestic(@view_model.potential_energy_rating),
        potential_energy_efficiency_rating: @view_model.potential_energy_rating,
        potential_energy_saving:
          Helper::EstimatedCostPotentialSavingHelper.new.potential_saving(
            @view_model.heating_cost_potential,
            @view_model.hot_water_cost_potential,
            @view_model.lighting_cost_potential,
            estimated_energy_cost,
          ),
        primary_energy_use: @view_model.primary_energy_use,
        energy_consumption_potential: @view_model.energy_consumption_potential,
        property_age_band: @view_model.property_age_band,
        property_summary: @view_model.property_summary,
        recommended_improvements:
          @view_model.improvements.map do |improvement|
            improvement[:energy_performance_band_improvement] =
              Helper::EnergyBandCalculator.domestic(
                improvement[:energy_performance_rating_improvement],
              )
            improvement
          end,
        related_party_disclosure_number:
          @view_model.related_party_disclosure_number,
        related_party_disclosure_text:
          @view_model.related_party_disclosure_text,
        tenure: @view_model.tenure,
        transaction_type: @view_model.transaction_type,
        total_floor_area: @view_model.total_floor_area,
        status: @view_model.status,
        country_code: @view_model.country_code,
        environmental_impact_current: @view_model.environmental_impact_current,
        environmental_impact_potential:
          @view_model.environmental_impact_potential,
      }
    end

    def to_report
      # TODO: change to ODC terms here
      all_main_heating_energy_efficiency = @view_model.all_main_heating_energy_efficiency
      { rrn: @view_model.assessment_id,
        type_of_assessment: "RdSAP",
        assessment_id: @view_model.assessment_id,
        lodgement_date: @view_model.date_of_registration,
        address_line1: @view_model.address_line1,
        address_line2: @view_model.address_line2,
        address_line3: @view_model.address_line3,
        address_line4: @view_model.address_line4,
        town: @view_model.town,
        postcode: @view_model.postcode,
        co2_emissions_current_per_floor_area:
          @view_model.co2_emissions_current_per_floor_area,
        mains_gas: @view_model.mains_gas,
        level: @view_model.level,
        top_storey: @view_model.top_storey,
        storey_count: @view_model.storey_count,
        mains_heating_controls: @view_model.mains_heating_controls,
        multiple_glazed_proportion: @view_model.multiple_glazed_proportion,
        glazed_area: @view_model.glazed_area,
        habitable_room_count: @view_model.habitable_room_count,
        heated_room_count: @view_model.heated_room_count,
        low_energy_lighting: @view_model.low_energy_lighting,
        fixed_lighting_outlets_count: @view_model.fixed_lighting_outlets_count,
        low_energy_fixed_lighting_outlets_count: @view_model.low_energy_fixed_lighting_outlets_count,
        open_fireplaces_count: @view_model.open_fireplaces_count,
        hot_water_description: @view_model.hot_water_description,
        hot_water_energy_efficiency_rating: @view_model.hot_water_energy_efficiency_rating,
        hot_water_environmental_efficiency_rating: @view_model.hot_water_environmental_efficiency_rating,
        wind_turbine_count: @view_model.wind_turbine_count,
        heat_loss_corridor: @view_model.heat_loss_corridor,
        unheated_corridor_length: @view_model.unheated_corridor_length,
        window_description: @view_model.window_description,
        window_energy_efficiency_rating: @view_model.window_energy_efficiency_rating,
        window_environmental_efficiency_rating: @view_model.window_environmental_efficiency_rating,
        secondary_heating_description: @view_model.secondary_heating_description,
        secondary_heating_energy_efficiency_rating: @view_model.secondary_heating_energy_efficiency_rating,
        secondary_heating_environmental_efficiency_rating: @view_model.secondary_heating_environmental_efficiency_rating,
        lighting_description: @view_model.lighting_description,
        lighting_energy_efficiency_rating: @view_model.lighting_energy_efficiency_rating,
        lighting_environmental_efficiency_rating: @view_model.lighting_environmental_efficiency_rating,
        photovoltaic_roof_area_percent: @view_model.photovoltaic_roof_area_percent,
        built_form: @view_model.built_form,
        mainheat_description: @view_model.all_main_heating_descriptions.join(", "),
        mainheat_energy_eff: energy_rating_string(all_main_heating_energy_efficiency[0]),
        mainheat_env_eff: energy_rating_string(all_main_heating_energy_efficiency[1]),
        extensions_count: @view_model.extensions_count,}
    end

    # @TODO Move method to helper class
    def energy_rating_string(input)
      number = input.to_i
      ratings = ["N/A", "Very Good", "Good", "Average", "Poor", "Very Poor"]
      number > ratings.length ? "N/A" : ratings[number]
    end

    def get_view_model
      @view_model
    end
  end
end
