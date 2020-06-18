module Domain
  class RenewableHeatIncentive
    def initialize(
      epcRrn: nil,
      assessorName: nil,
      reportType: nil,
      inspectionDate: nil,
      lodgementDate: nil,
      dwellingType: nil,
      postcode: nil,
      propertyAgeBand: nil,
      tenure: nil,
      totalFloorArea: nil,
      cavityWallInsulation: nil,
      loftInsulation: nil,
      spaceHeating: nil,
      waterHeating: nil,
      secondaryHeating: nil,
      currentRating: nil,
      currentBand: nil,
      potentialRating: nil,
      potentialBand: nil
    )
      @epcRrn = epcRrn,
      @assessorName = assessorName,
      @reportType = reportType,
      @inspectionDate = inspectionDate,
      @lodgementDate = lodgementDate,
      @dwellingType = dwellingType,
      @postcode = postcode,
      @propertyAgeBand = propertyAgeBand,
      @tenure = tenure,
      @totalFloorArea = totalFloorArea,
      @cavityWallInsulation = cavityWallInsulation,
      @loftInsulation = loftInsulation,
      @spaceHeating = spaceHeating,
      @waterHeating = waterHeating,
      @secondaryHeating = secondaryHeating,
      @currentRating = currentRating,
      @currentBand = currentBand,
      @potentialRating = potentialRating,
      @potentialBand = potentialBand
    end

    def to_hash
      {
        epcRrn: @epcRrn.first,
        assessorName: @assessorName,
        reportType: @reportType,
        inspectionDate: @inspectionDate.strftime("%Y-%m-%d"),
        lodgementDate: @lodgementDate.strftime("%Y-%m-%d"),
        dwellingType: @dwellingType,
        postcode: @postcode,
        propertyAgeBand: @propertyAgeBand,
        tenure: @tenure,
        totalFloorArea: @totalFloorArea.to_f,
        cavityWallInsulation: @cavityWallInsulation,
        loftInsulation: @loftInsulation,
        spaceHeating: @spaceHeating.to_s,
        waterHeating: @waterHeating.to_s,
        secondaryHeating: @secondaryHeating,
        energyEfficiency: {
          currentRating: @currentRating,
          currentBand: get_energy_rating_band(@currentBand),
          potentialRating: @potentialRating,
          potentialBand: get_energy_rating_band(@potentialBand),
        },
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
