module UseCase
  class FetchAssessmentForEcoPlus
    include DomesticDigestHelper

    def initialize(domestic_digest_gateway:, assessments_search_gateway:)
      @domestic_digest_gateway = domestic_digest_gateway
      @assessments_search_gateway = assessments_search_gateway
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest(rrn:)
      return nil if domestic_digest.nil?

      assessment_summary = @assessments_search_gateway.search_by_assessment_id(rrn)
      return nil if assessment_summary.nil?

      assessment_summary = assessment_summary.first.to_hash

      Domain::AssessmentEcoPlusDetails.new(
        type_of_assessment: domestic_digest[:type_of_assessment],
        address: domestic_digest[:address].transform_values { |v| v || "" },
        uprn: assessment_summary[:address_id],
        lodgement_date: domestic_digest[:date_of_registration],
        current_energy_efficiency_rating: domestic_digest[:current_energy_efficiency_rating],
        potential_energy_efficiency_rating: domestic_digest[:potential_energy_efficiency_rating],
        property_type: !domestic_digest[:dwelling_type].nil? && !domestic_digest[:dwelling_type].empty? ? domestic_digest[:dwelling_type] : nil,
        built_form: domestic_digest[:built_form],
        main_heating_description: !domestic_digest[:main_heating_category].nil? && !domestic_digest[:main_heating_category].empty? ? domestic_digest[:main_heating_category] : nil,
        walls_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "wall"),
        roof_description: pluck_property_summary_descriptions(domestic_digest:, feature_type: "roof"),
        cavity_wall_insulation_recommended: has_domestic_recommendation?(type: "B", summary: domestic_digest),
        loft_insulation_recommended: has_domestic_recommendation?(type: "A", summary: domestic_digest),
      )
    end

  private

    DOMESTIC_TYPES = %w[
      RdSAP
      SAP
    ].freeze

    def has_domestic_recommendation?(type:, summary:)
      unless DOMESTIC_TYPES.include? summary[:type_of_assessment]
        return nil
      end

      summary[:recommended_improvements].any? { |improvement| improvement[:improvement_type] == type }
    end

    attr_reader :domestic_digest_gateway
  end
end
