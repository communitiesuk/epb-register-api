module Domain
  class AssessmentRetrofitFundingDetails
    def initialize(
      address:,
      uprn:,
      lodgement_date:,
      current_band:
    )
      @address = address
      @lodgement_date = lodgement_date
      @uprn = uprn.sub("UPRN-", "")
      @current_band = current_band
    end

    def to_hash
      {
        address: @address,
        uprn: @uprn,
        lodgement_date: @lodgement_date,
        current_band: @current_band,
      }
    end
  end
end
