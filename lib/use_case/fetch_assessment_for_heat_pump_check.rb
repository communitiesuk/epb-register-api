module UseCase
  class FetchAssessmentForHeatPumpCheck
    include DomesticDigestHelper

    def initialize(domestic_digest_gateway:, summary_use_case:)
      @domestic_digest_gateway = domestic_digest_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest rrn: rrn
      return nil if domestic_digest.nil?

      assessment_summary = get_assessment_summary(rrn:)

      Domain::AssessmentForHeatPumpCheck.new address: domestic_digest[:address].transform_values { |v| v || "" },
                                             lodgement_date: domestic_digest[:date_of_registration],
                                             is_latest_assessment_for_address: !assessment_summary[:superseded_by],
                                             property_type: domestic_digest[:dwelling_type],
                                             built_form: domestic_digest[:built_form],
                                             property_age_band: strip_england_and_wales_prefix(domestic_digest[:main_dwelling_construction_age_band_or_year]),
                                             walls_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "wall"),
                                             roof_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "roof"),
                                             windows_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "window"),
                                             main_fuel_type: domestic_digest[:main_fuel_type],
                                             total_floor_area: !domestic_digest[:total_floor_area].nil? ? domestic_digest[:total_floor_area].to_i : nil,
                                             has_mains_gas: !domestic_digest[:has_mains_gas].nil? ? domestic_digest[:has_mains_gas] == "Y" : nil,
                                             current_energy_efficiency_rating: !domestic_digest[:current_energy_efficiency_rating].nil? ? domestic_digest[:current_energy_efficiency_rating] : nil
    end

  private

    attr_reader :domestic_digest_gateway, :summary_use_case
  end
end
