module Domain
  class AssessmentForHeatPumpCheck
    def initialize(
      address:,
      lodgement_date:,
      is_latest_assessment_for_address:,
      property_type:,
      built_form:,
      property_age_band:,
      walls_description:,
      roof_description:,
      windows_description:,
      main_fuel_type:,
      total_floor_area:,
      has_mains_gas:,
      current_energy_efficiency_rating:
    )
      @address = address
      @lodgement_date = lodgement_date
      @is_latest_assessment_for_address = is_latest_assessment_for_address
      @property_type = property_type
      @built_form = built_form
      @property_age_band = property_age_band
      @walls_description = walls_description
      @roof_description = roof_description
      @windows_description = windows_description
      @main_fuel_type = main_fuel_type
      @total_floor_area = total_floor_area
      @has_mains_gas = has_mains_gas
      @current_energy_efficiency_rating = current_energy_efficiency_rating
    end

    def to_hash
      {
        address: @address,
        lodgement_date: @lodgement_date,
        is_latest_assessment_for_address: @is_latest_assessment_for_address,
        property_type: @property_type,
        built_form: @built_form,
        property_age_band: @property_age_band,
        walls_description: @walls_description,
        roof_description: @roof_description,
        windows_description: @windows_description,
        main_fuel_type: @main_fuel_type,
        total_floor_area: @total_floor_area,
        has_mains_gas: @has_mains_gas,
        current_energy_efficiency_rating: @current_energy_efficiency_rating,
      }
    end
  end
end
