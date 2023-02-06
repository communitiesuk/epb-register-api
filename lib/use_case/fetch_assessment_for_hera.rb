module UseCase
  class FetchAssessmentForHera
    include DomesticDigestHelper

    def initialize(domestic_digest_gateway:, summary_use_case:)
      @domestic_digest_gateway = domestic_digest_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest(rrn:)
      return nil if domestic_digest.nil?

      assessment_summary = get_assessment_summary(rrn:)

      Domain::AssessmentHeraDetails.new type_of_assessment: domestic_digest[:type_of_assessment],
                                        address: domestic_digest[:address].transform_values { |v| v || "" },
                                        lodgement_date: domestic_digest[:date_of_registration],
                                        is_latest_assessment_for_address: !assessment_summary[:superseded_by],
                                        property_type: !domestic_digest[:dwelling_type].nil? && !domestic_digest[:dwelling_type].empty? ? domestic_digest[:dwelling_type] : nil,
                                        built_form: domestic_digest[:built_form],
                                        property_age_band: strip_england_and_wales_prefix(domestic_digest[:main_dwelling_construction_age_band_or_year]),
                                        walls_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "wall"),
                                        floor_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "floor"),
                                        roof_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "roof"),
                                        windows_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "window"),
                                        main_heating_description: !domestic_digest[:main_heating_category].nil? && !domestic_digest[:main_heating_category].empty? ? domestic_digest[:main_heating_category] : nil,
                                        main_fuel_type: domestic_digest[:main_fuel_type],
                                        has_hot_water_cylinder: domestic_digest[:has_hot_water_cylinder] == "true"
    end

  private

    attr_reader :domestic_digest_gateway, :summary_use_case
  end
end
