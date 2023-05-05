module UseCase
  class FetchAssessmentForRetrofitFundingScheme
    def initialize(retrofit_funding_scheme_gateway:, assessments_search_gateway:)
      @retrofit_funding_scheme_gateway = retrofit_funding_scheme_gateway
      @assessments_search_gateway = assessments_search_gateway
    end

    def execute(uprn)
      assessment_id = @retrofit_funding_scheme_gateway.find_by_uprn(uprn)
      return nil if assessment_id.nil?

      assessment_summary = @assessments_search_gateway.search_by_assessment_id(assessment_id).first.to_hash
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
        uprn: assessment_summary[:address_id],
        current_band: assessment_summary[:current_energy_efficiency_band],
      )
    end

  private

    attr_reader :retrofit_funding_scheme_gateway, :assessments_search_gateway
  end
end
