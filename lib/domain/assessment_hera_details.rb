module Domain
  class AssessmentHeraDetails
    def initialize(
      type_of_assessment:,
      address:,
      lodgement_date:,
      is_latest_assessment_for_address:,
      property_type:,
      built_form:,
      property_age_band:,
      walls_description:,
      floor_description:,
      roof_description:,
      windows_description:,
      main_heating_description:,
      main_fuel_type:,
      has_hot_water_cylinder:
    )
      @type_of_assessment = type_of_assessment
      @address = address
      @lodgement_date = lodgement_date
      @is_latest_assessment_for_address = is_latest_assessment_for_address
      @property_type = property_type
      @built_form = built_form
      @property_age_band = property_age_band
      @walls_description = walls_description
      @floor_description = floor_description
      @roof_description = roof_description
      @windows_description = windows_description
      @main_heating_description = main_heating_description
      @main_fuel_type = main_fuel_type
      @has_hot_water_cylinder = has_hot_water_cylinder
    end

    def to_hash
      {
        type_of_assessment: @type_of_assessment,
        address: @address,
        lodgement_date: @lodgement_date,
        is_latest_assessment_for_address: @is_latest_assessment_for_address,
        property_type: @property_type,
        built_form: @built_form,
        property_age_band: @property_age_band,
        walls_description: @walls_description,
        floor_description: @floor_description,
        roof_description: @roof_description,
        windows_description: @windows_description,
        main_heating_description: @main_heating_description,
        main_fuel_type: @main_fuel_type,
        has_hot_water_cylinder: @has_hot_water_cylinder,
      }
    end
  end
end
