module ViewModel::Export
  class DomesticExportView < ExportBaseView
    def initialize(certificate_wrapper)
      @wrapper = certificate_wrapper
      @view_model = certificate_wrapper.get_view_model
    end

    def build
      view = {}
      view[:addendum] = @view_model.addendum
      view[:address] = address
      view[:assessment_id] = @view_model.assessment_id
      view[:assessor] = assessor
      view[:built_form] =
        Helper::XmlEnumsToOutput.xml_value_to_string(@view_model.built_form)
      view[:co2_emissions_current_per_floor_area] =
        @view_model.co2_emissions_current_per_floor_area.to_i
      view[:construction_age_band] =
        enum_value(
          :construction_age_band_lookup,
          @view_model.main_dwelling_construction_age_band_or_year,
          @wrapper.schema_type,
          @wrapper.report_type,
        )
      view[:current_carbon_emission] = @view_model.current_carbon_emission.to_f
      view[:current_energy_efficiency_band] =
        Helper::EnergyBandCalculator.domestic(@view_model.current_energy_rating)
      view[:current_energy_efficiency_rating] =
        @view_model.current_energy_rating
      view[:date_of_assessment] = @view_model.date_of_assessment
      view[:date_of_expiry] = @view_model.date_of_expiry
      view[:date_of_registration] = @view_model.date_of_registration
      view[:dwelling_type] = @view_model.dwelling_type
      view[:energy_consumption_potential] =
        @view_model.energy_consumption_potential.to_i
      view[:environmental_impact_current] =
        @view_model.environmental_impact_current.to_i
      view[:environmental_impact_potential] =
        @view_model.environmental_impact_potential.to_i
      view[:extensions_count] = @view_model.extensions_count unless @view_model
        .extensions_count.nil?
      view[:fixed_lighting_outlets_count] =
        @view_model.fixed_lighting_outlets_count.to_i
      view[:glazed_area] = @view_model.glazed_area unless @view_model
        .glazed_area.nil?
      unless @view_model.habitable_room_count.nil?
        view[:habitable_room_count] = @view_model.habitable_room_count
      end
      view[:heat_demand] = heat_demand
      unless @view_model.heat_loss_corridor.nil?
        view[:heat_loss_corridor] = @view_model.heat_loss_corridor
      end
      unless @view_model.heated_room_count.nil?
        view[:heated_room_count] = @view_model.heated_room_count
      end
      view[:heating_cost_current] = @view_model.heating_cost_current.to_f
      view[:heating_cost_potential] = @view_model.heating_cost_potential.to_f
      view[:hot_water_cost_current] = @view_model.hot_water_cost_current.to_f
      view[:hot_water_cost_potential] =
        @view_model.hot_water_cost_potential.to_f
      view[:hot_water_description] = @view_model.hot_water_description
      view[:hot_water_energy_efficiency_rating] =
        @view_model.hot_water_energy_efficiency_rating.to_i
      view[:hot_water_environmental_efficiency_rating] =
        @view_model.hot_water_environmental_efficiency_rating.to_i
      view[:level] = @view_model.level.to_i
      view[:lighting_cost_current] = @view_model.lighting_cost_current.to_f
      view[:lighting_cost_potential] = @view_model.lighting_cost_potential.to_f
      view[:lighting_description] = @view_model.lighting_description
      view[:lighting_energy_efficiency_rating] =
        @view_model.lighting_energy_efficiency_rating.to_i
      view[:lighting_environmental_efficiency_rating] =
        @view_model.lighting_environmental_efficiency_rating.to_i
      view[:low_energy_fixed_lighting_outlets_count] =
        @view_model.low_energy_fixed_lighting_outlets_count.to_i
      view[:low_energy_lighting] = @view_model.low_energy_lighting.to_i
      view[:main_fuel_type] = @view_model.main_fuel_type
      view[:main_heating_controls_descriptions] =
        @view_model.all_main_heating_controls_descriptions
      view[:main_heating_descriptions] =
        @view_model.all_main_heating_descriptions
      view[:mains_gas] = @view_model.mains_gas unless @view_model.mains_gas.nil?
      view[:multiple_glazed_proportion] =
        @view_model.multiple_glazed_proportion.to_i
      view[:open_fireplaces_count] = @view_model.open_fireplaces_count.to_i
      unless @view_model.photovoltaic_roof_area_percent.nil?
        view[:photovoltaic_roof_area_percent] =
          @view_model.photovoltaic_roof_area_percent
      end
      view[:potential_carbon_emission] =
        @view_model.potential_carbon_emission.to_f
      view[:potential_energy_efficiency_band] =
        Helper::EnergyBandCalculator.domestic(
          @view_model.potential_energy_rating,
        )
      view[:potential_energy_efficiency_rating] =
        @view_model.potential_energy_rating
      view[:primary_energy_use] = @view_model.primary_energy_use.to_i
      view[:property_age_band] = @view_model.property_age_band
      view[:property_summary] = @view_model.property_summary
      view[:property_type] =
        enum_value(:property_type, @view_model.property_type)
      view[:recommended_improvements] =
        @view_model.improvements.map do |improvement|
          improvement[:energy_performance_band_improvement] =
            Helper::EnergyBandCalculator.domestic(
              improvement[:energy_performance_rating_improvement],
            )
          improvement
        end
      view[:related_party_disclosure_number] =
        @view_model.related_party_disclosure_number
      view[:related_party_disclosure_text] =
        @view_model.related_party_disclosure_text
      view[:secondary_heating_description] =
        @view_model.secondary_heating_description
      view[:secondary_heating_energy_efficiency_rating] =
        @view_model.secondary_heating_energy_efficiency_rating.to_i
      view[:secondary_heating_environmental_efficiency_rating] =
        @view_model.secondary_heating_environmental_efficiency_rating.to_i
      view[:status] = @view_model.status

      # storey_count is RdSAP only
      view[:storey_count] = @view_model.storey_count unless @view_model
        .storey_count.nil?
      view[:tenure] = enum_value(:tenure, @view_model.tenure)
      view[:top_storey] = @view_model.top_storey
      view[:total_floor_area] = @view_model.total_floor_area.to_f
      view[:transaction_type] =
        enum_value(:transaction_type, @view_model.transaction_type)
      view[:type_of_assessment] = @view_model.type_of_assessment
      unless @view_model.unheated_corridor_length.nil?
        view[:unheated_corridor_length] = @view_model.unheated_corridor_length
      end
      view[:wind_turbine_count] = @view_model.wind_turbine_count.to_i
      view[:window_description] = @view_model.window_description
      view[:window_energy_efficiency_rating] =
        @view_model.window_energy_efficiency_rating.to_i
      view[:window_environmental_efficiency_rating] =
        @view_model.window_environmental_efficiency_rating.to_i

      # date_registered is removed as duplicate of date_of_registration
      # estimated_energy_cost is removed since this is a calculated value

      view
    end
  end
end
