module UseCase
  class FetchAssessmentForRetrofitFundingScheme
    include DomesticDigestHelper

    def initialize(retrofit_funding_scheme_gateway:, assessments_search_gateway:, domestic_digest_gateway:)
      @retrofit_funding_scheme_gateway = retrofit_funding_scheme_gateway
      @assessments_search_gateway = assessments_search_gateway
      @domestic_digest_gateway = domestic_digest_gateway
    end

    def execute(uprn)
      rrn = @retrofit_funding_scheme_gateway.find_by_uprn(uprn)
      return nil if rrn.nil?

      domestic_digest = get_domestic_digest(rrn:)
      return nil if domestic_digest.nil?

      assessment_summary = @assessments_search_gateway.search_by_assessment_id(rrn).first.to_hash
      return nil if assessment_summary.nil?

      Domain::AssessmentRetrofitFundingDetails.new(
        address: {
          address_line1: assessment_summary[:address_line1],
          address_line2: assessment_summary[:address_line2],
          address_line3: assessment_summary[:address_line3],
          address_line4: assessment_summary[:address_line4],
          town: assessment_summary[:town],
          postcode: assessment_summary[:postcode],
        },
        lodgement_date: assessment_summary[:date_of_registration],
        expiry_date: assessment_summary[:date_of_expiry],
        uprn: assessment_summary[:address_id],
        current_band: assessment_summary[:current_energy_efficiency_band],
        property_type: !domestic_digest[:dwelling_type].nil? && !domestic_digest[:dwelling_type].empty? ? domestic_digest[:dwelling_type] : nil,
        built_form: domestic_digest[:built_form],
      )
    end

  private

    attr_reader :retrofit_funding_scheme_gateway, :assessments_search_gateway, :domestic_digest_gateway
  end
end
