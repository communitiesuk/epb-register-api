module ViewModel::Export
  class CommercialExportView < ViewModel::Export::ExportBaseView
    def build
      view = {}
      view[:type_of_assessment] = type_of_assessment
      view[:address] = address
      view[:assessor] = assessor
      view[:building_emission_rate] = @view_model.building_emission_rate
      view[:date_of_expiry] = @view_model.date_of_expiry
      view[:report_type] = @view_model.report_type
      view[:date_of_assessment] = @view_model.date_of_assessment
      view[:date_of_registration] = @view_model.date_of_registration
      view[:technical_information] = {
        main_heating_fuel: @view_model.main_heating_fuel,
        building_environment: @view_model.building_environment,
        floor_area: @view_model.floor_area,
        building_level: @view_model.building_level,
      }
      view[:primary_energy_use] = @view_model.primary_energy_use
      view[:related_rrn] = @view_model.related_rrn
      view[:new_build_rating] = @view_model.new_build_rating
      view[:related_party_disclosure] = @view_model.epc_related_party_disclosure
      view[:property_type] = @view_model.property_type
      view[:building_complexity] = @view_model.building_level
      view[:energy_efficiency_rating] = @view_model.energy_efficiency_rating
      view[:current_energy_efficiency_rating] =
        @view_model.energy_efficiency_rating
      view[:current_energy_efficiency_band] =
        Helper::EnergyBandCalculator.commercial(
          @view_model.energy_efficiency_rating.to_i,
        )
      view[:new_build_band] =
        Helper::EnergyBandCalculator.commercial(
          @view_model.new_build_rating.to_i,
        )
      view[:existing_build_rating] = @view_model.existing_build_rating
      view[:existing_build_band] =
        Helper::EnergyBandCalculator.commercial(
          @view_model.existing_build_rating.to_i,
        )
      view[:ac_inspection_commissioned] = @view_model.ac_inspection_commissioned
      view[:aircon_kw_rating] = @view_model.ac_kw_rating
      view[:aircon_present] = @view_model.ac_present unless @view_model
        .ac_present.nil?
      view[:asset_rating] = @view_model.energy_efficiency_rating
      view[:asset_rating_band] =
        Helper::EnergyBandCalculator.commercial(
          @view_model.energy_efficiency_rating.to_i,
        )
      view
    end
  end
end
