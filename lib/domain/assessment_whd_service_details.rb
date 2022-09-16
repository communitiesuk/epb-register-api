module Domain
  class AssessmentWhdServiceDetails
    def initialize(
      address:,
      lodgement_date:,
      is_latest_assessment_for_address:,
      property_type:,
      built_form:,
      property_age_band:,
      total_floor_area:
    )
      @address = address
      @lodgement_date = lodgement_date
      @is_latest_assessment_for_address = is_latest_assessment_for_address
      @property_type = property_type
      @built_form = built_form
      @property_age_band = property_age_band
      @total_floor_area = total_floor_area
    end

    def to_hash
      {
        address: @address,
        lodgement_date: @lodgement_date,
        is_latest_assessment_for_address: @is_latest_assessment_for_address,
        property_type: @property_type,
        built_form: @built_form,
        property_age_band: @property_age_band,
        total_floor_area: @total_floor_area
      }
    end
  end
end
