module Domain
  class AssessmentRetrofitFundingDetails
    def initialize(
      address:,
      uprn:,
      lodgement_date:,
      current_energy_efficiency_rating:
    )
      @address = address
      @lodgement_date = lodgement_date
      @uprn = uprn.sub("UPRN-", "")
      @current_energy_efficiency_rating = current_energy_efficiency_rating
    end

    def to_hash
      {
        address: @address,
        uprn: @uprn,
        lodgement_date: @lodgement_date,
        current_band:
        Helper::EnergyBandCalculator.domestic(
          @current_energy_efficiency_rating,
        ),
      }
    end
  end
end
