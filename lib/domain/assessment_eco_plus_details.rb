module Domain
  class AssessmentEcoPlusDetails
    def initialize(
      type_of_assessment:,
      address:,
      uprn:,
      lodgement_date:,
      current_energy_efficiency_rating:,
      potential_energy_efficiency_rating:,
      property_type:,
      built_form:,
      main_heating_description:,
      walls_description:,
      roof_description:,
      cavity_wall_insulation_recommended:,
      loft_insulation_recommended:
    )
      @type_of_assessment = type_of_assessment
      @address = address
      @uprn = uprn.include?("UPRN") ? uprn.sub("UPRN-", "") : nil
      @lodgement_date = lodgement_date
      @current_energy_efficiency_rating = current_energy_efficiency_rating
      @current_energy_efficiency_band = Helper::EnergyBandCalculator.domestic(
        @current_energy_efficiency_rating,
      )
      @potential_energy_efficiency_rating = potential_energy_efficiency_rating
      @potential_energy_efficiency_band = Helper::EnergyBandCalculator.domestic(
        @potential_energy_efficiency_rating,
      )
      @property_type = property_type
      @built_form = built_form
      @main_heating_description = main_heating_description
      @walls_description = walls_description
      @roof_description = roof_description
      @cavity_wall_insulation_recommended = cavity_wall_insulation_recommended
      @loft_insulation_recommended = loft_insulation_recommended
    end

    def to_hash
      {
        type_of_assessment: @type_of_assessment,
        address: @address,
        uprn: @uprn,
        lodgement_date: @lodgement_date,
        current_energy_efficiency_rating: @current_energy_efficiency_rating,
        current_energy_efficiency_band: @current_energy_efficiency_band,
        potential_energy_efficiency_rating: @potential_energy_efficiency_rating,
        potential_energy_efficiency_band: @potential_energy_efficiency_band,
        property_type: @property_type,
        built_form: @built_form,
        main_heating_description: @main_heating_description,
        walls_description: @walls_description,
        roof_description: @roof_description,
        cavity_wall_insulation_recommended: @cavity_wall_insulation_recommended,
        loft_insulation_recommended: @loft_insulation_recommended,
      }
    end
  end
end
