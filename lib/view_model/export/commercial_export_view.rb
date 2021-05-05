module ViewModel::Export
  class CommercialExportView < ViewModel::Export::ExportBaseView
    def build
      {
        type_of_assessment: type_of_assessment,
        address: address,
        assessor: assessor,
        building_emission_rate: @view_model.building_emission_rate,
        date_of_expiry: @view_model.date_of_expiry,
        report_type: @view_model.report_type,
        date_of_assessment: @view_model.date_of_assessment,
        date_of_registration: @view_model.date_of_registration,
        technical_information: {
          main_heating_fuel: @view_model.main_heating_fuel,
          building_environment: @view_model.building_environment,
          floor_area: @view_model.floor_area,
          building_level: @view_model.building_level,
        },
        primary_energy_use: @view_model.primary_energy_use,
        related_rrn: @view_model.related_rrn,
        new_build_rating: @view_model.new_build_rating,
        related_party_disclosure: @view_model.epc_related_party_disclosure,
        property_type: @view_model.property_type,
        building_complexity: @view_model.building_level,
        energy_efficiency_rating: @view_model.energy_efficiency_rating,
        current_energy_efficiency_rating: @view_model.energy_efficiency_rating,
        current_energy_efficiency_band:
          Helper::EnergyBandCalculator.commercial(
            @view_model.energy_efficiency_rating.to_i,
          ),
        new_build_band:
          Helper::EnergyBandCalculator.commercial(
            @view_model.new_build_rating.to_i,
          ),
        existing_build_rating: @view_model.existing_build_rating,
        existing_build_band:
          Helper::EnergyBandCalculator.commercial(
            @view_model.existing_build_rating.to_i,
          ),
      }
    end
  end
end
