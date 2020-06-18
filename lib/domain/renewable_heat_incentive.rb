module Domain
  class RenewableHeatIncentive
    def initialize(
      epc_rrn:,
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
        space_heating: @space_heating.to_i,
        water_heating: @water_heating.to_i,
        secondary_heating: @secondary_heating,
        energy_efficiency: @energy_efficiency,
      }
    end

  private

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
      when 92..1_000
        "a"
      end
    end
  end
end
