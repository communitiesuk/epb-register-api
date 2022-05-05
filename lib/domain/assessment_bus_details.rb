module Domain
  class AssessmentBusDetails
    def initialize(
      epc_rrn:,
      report_type:,
      expiry_date:,
      cavity_wall_insulation_recommended:,
      loft_insulation_recommended:,
      secondary_heating:,
      address:,
      dwelling_type:
    )
      @epc_rrn = epc_rrn
      @report_type = report_type
      @expiry_date = Date.strptime(expiry_date.to_s, "%Y-%m-%d")
      @cavity_wall_insulation_recommended = cavity_wall_insulation_recommended
      @loft_insulation_recommended = loft_insulation_recommended
      @secondary_heating = secondary_heating
      @address = address
      @dwelling_type = dwelling_type
    end

    def to_hash
      {
        epc_rrn: @epc_rrn,
        report_type: @report_type,
        expiry_date: @expiry_date.strftime("%Y-%m-%d"),
        cavity_wall_insulation_recommended: @cavity_wall_insulation_recommended,
        loft_insulation_recommended: @loft_insulation_recommended,
        secondary_heating: @secondary_heating,
        address: @address,
        dwelling_type: @dwelling_type,
      }
    end

    def rrn
      @epc_rrn
    end
  end
end
