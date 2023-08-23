module Domain
  class AssessmentWarmHomeDiscountServiceDetails
    def initialize(
      address:,
      lodgement_date:,
      is_latest_assessment_for_address:,
      property_type:,
      built_form:,
      property_age_band:,
      total_floor_area:,
      type_of_property:,
      address_id:
    )
      @address = address
      @lodgement_date = lodgement_date
      @is_latest_assessment_for_address = is_latest_assessment_for_address
      @property_type = property_type
      @built_form = built_form
      @property_age_band = property_age_band
      @total_floor_area = total_floor_area
      @type_of_property = type_of_property
      @address_id = address_id
    end

    def to_hash
      {
        address: @address,
        lodgement_date: @lodgement_date,
        is_latest_assessment_for_address: @is_latest_assessment_for_address,
        property_type: @property_type,
        built_form: @built_form,
        property_age_band: @property_age_band,
        total_floor_area: @total_floor_area,
        type_of_property: @type_of_property,
        uprn: @address_id.include?("UPRN") ? @address_id.sub("UPRN-", "") : nil,
      }
    end
  end
end
