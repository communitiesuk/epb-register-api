module Domain
  class AssessmentHeraDetails
    include Helper::DomesticDigestHelper

    def initialize(
      assessment_summary:,
      domestic_digest:
    )
      @assessment_summary = assessment_summary
      @domestic_digest = domestic_digest
    end

    def to_hash
      {
        type_of_assessment: @domestic_digest[:type_of_assessment],
        address: @domestic_digest[:address].transform_values { |v| v || "" },
        lodgement_date: @domestic_digest[:date_of_registration],
        is_latest_assessment_for_address: !@assessment_summary[:superseded_by],
        property_type: !@domestic_digest[:dwelling_type].nil? && !@domestic_digest[:dwelling_type].empty? ? @domestic_digest[:dwelling_type] : nil,
        built_form: @domestic_digest[:built_form],
        property_age_band: strip_england_and_wales_prefix(@domestic_digest[:main_dwelling_construction_age_band_or_year]),
        walls_description: pluck_property_summary_descriptions(domestic_digest: @domestic_digest, feature_type: "wall"),
        floor_description: pluck_property_summary_descriptions(domestic_digest: @domestic_digest, feature_type: "floor"),
        roof_description: pluck_property_summary_descriptions(domestic_digest: @domestic_digest, feature_type: "roof"),
        windows_description: pluck_property_summary_descriptions(domestic_digest: @domestic_digest, feature_type: "window"),
        main_heating_description: !@domestic_digest[:main_heating_category].nil? && !@domestic_digest[:main_heating_category].empty? ? @domestic_digest[:main_heating_category] : nil,
        main_fuel_type: @domestic_digest[:main_fuel_type],
        has_hot_water_cylinder: @domestic_digest[:has_hot_water_cylinder] == "true",
        photo_supply: @domestic_digest[:photo_supply],
        main_heating_controls: @domestic_digest[:main_heating_controls],
      }
    end
  end
end
