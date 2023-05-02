module UseCase
  class FetchAssessmentForRetrofitFundingScheme
    def initialize(retrofit_funding_scheme_gateway:, assessments_search_gateway:)
      @retrofit_funding_scheme_gateway = retrofit_funding_scheme_gateway
      @assessments_search_gateway = assessments_search_gateway
    end

    def execute(uprn)
      assessment_id = @retrofit_funding_scheme_gateway.find_by_uprn(uprn)
      return nil if assessment_id.nil?

      assessment_summary = @assessments_search_gateway.search_by_assessment_id(assessment_id)

      Domain::AssessmentRetrofitFundingDetails.new(
        address: assessment_summary[:address].slice(
          :address_line1,
          :address_line2,
          :address_line3,
          :address_line4,
          :town,
          :postcode,
        ).transform_values { |v| v || "" },
        lodgement_date: assessment_summary[:date_registered],
        uprn: assessment_summary[:address_id],
        current_energy_efficiency_rating: assessment_summary[:current_energy_efficiency_rating],
      )
    end

  private

    attr_reader :retrofit_funding_scheme_gateway, :assessments_search_gateway
  end
end
