module Domain
  class RenewableHeatIncentive
    def initialize(
      epc_rrn:,
      is_cancelled:,
      assessor_name:,
      report_type:,
      inspection_date:,
      lodgement_date:,
      dwelling_type:,
      postcode:,
      property_age_band:,
      tenure:,
      total_floor_area:,
      cavity_wall_insulation:,
      loft_insulation:,
      space_heating:,
      water_heating:,
      secondary_heating:,
      energy_efficiency:
    )
      @epc_rrn = epc_rrn
      @is_cancelled = is_cancelled
      @assessor_name = assessor_name
      @report_type = report_type
      @inspection_date = inspection_date
      @lodgement_date = lodgement_date
      @dwelling_type = dwelling_type
      @postcode = postcode
      @property_age_band = property_age_band
      @tenure = tenure
      @total_floor_area = total_floor_area
      @cavity_wall_insulation = cavity_wall_insulation
      @loft_insulation = loft_insulation
      @space_heating = space_heating
      @water_heating = water_heating
      @secondary_heating = secondary_heating
      @energy_efficiency = energy_efficiency
    end

    def to_hash
      {
        epc_rrn: @epc_rrn,
        is_cancelled: @is_cancelled,
        assessor_name: @assessor_name,
        report_type: @report_type,
        inspection_date: @inspection_date.strftime("%Y-%m-%d"),
        lodgement_date: @lodgement_date.strftime("%Y-%m-%d"),
        dwelling_type: @dwelling_type,
        postcode: @postcode,
        property_age_band: @property_age_band,
        tenure: @tenure,
        total_floor_area: @total_floor_area.to_f,
        cavity_wall_insulation: @cavity_wall_insulation,
        loft_insulation: @loft_insulation,
        space_heating: @space_heating.to_f,
        water_heating: @water_heating,
        secondary_heating: @secondary_heating,
        energy_efficiency: @energy_efficiency,
      }
    end
  end
end
