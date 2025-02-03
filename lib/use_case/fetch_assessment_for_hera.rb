module UseCase
  class FetchAssessmentForHera
    include Helper::DomesticDigestHelper

    def initialize(domestic_digest_gateway:, summary_use_case:)
      @domestic_digest_gateway = domestic_digest_gateway
      @summary_use_case = summary_use_case
    end

    def execute(rrn:)
      domestic_digest = get_domestic_digest(rrn:)
      return nil if domestic_digest.nil?

      assessment_summary = get_assessment_summary(rrn:)

      Domain::AssessmentHeraDetails.new(
        assessment_summary:,
        domestic_digest:,
      )
    end

  private

    attr_reader :domestic_digest_gateway, :summary_use_case
  end
end
