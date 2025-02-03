module UseCase
  class FetchAssessmentForWarmHomeDiscountService
    include Helper::DomesticDigestHelper

    def initialize(domestic_digest_gateway:, summary_use_case:)
      @domestic_digest_gateway = domestic_digest_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest(rrn:)
      return nil if domestic_digest.nil?

      assessment_summary = get_assessment_summary(rrn:)
      Domain::AssessmentWarmHomeDiscountServiceDetails.new address: domestic_digest[:address].transform_values { |v| v || "" },
                                                           lodgement_date: domestic_digest[:date_of_registration],
                                                           is_latest_assessment_for_address: !assessment_summary[:superseded_by],
                                                           property_type: !domestic_digest[:dwelling_type].nil? && !domestic_digest[:dwelling_type].empty? ? domestic_digest[:dwelling_type] : nil,
                                                           built_form: domestic_digest[:built_form],
                                                           property_age_band: strip_england_and_wales_prefix(domestic_digest[:main_dwelling_construction_age_band_or_year]),
                                                           total_floor_area: !domestic_digest[:total_floor_area].nil? && !domestic_digest[:total_floor_area].empty? ? domestic_digest[:total_floor_area].to_i : nil,
                                                           type_of_property: domestic_digest[:type_of_property],
                                                           address_id: assessment_summary[:address_id]
    end

  private

    attr_reader :domestic_digest_gateway, :summary_use_case
  end
end
