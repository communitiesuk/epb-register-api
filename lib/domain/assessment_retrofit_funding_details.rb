module Domain
  class AssessmentRetrofitFundingDetails
    def initialize(
      address:,
      uprn:,
      lodgement_date:,
      expiry_date:,
      current_band:,
      property_type:,
      built_form:
    )
      @address = address
      @uprn = uprn.sub("UPRN-", "")
      @lodgement_date = lodgement_date
      @expiry_date = Date.strptime(expiry_date.to_s, "%Y-%m-%d")
      @current_band = current_band
      @property_type = property_type
      @built_form = built_form
    end

    def to_hash
      {
        address: @address,
        uprn: @uprn,
        lodgement_date: @lodgement_date,
        expiry_date: @expiry_date.strftime("%Y-%m-%d"),
        current_band: @current_band,
        property_type: @property_type,
        built_form: @built_form,
      }
    end
  end
end
