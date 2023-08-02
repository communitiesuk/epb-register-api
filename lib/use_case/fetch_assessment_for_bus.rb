module UseCase
  class FetchAssessmentForBus
    def initialize(bus_gateway:, summary_use_case:, domestic_digest_gateway:)
      @bus_gateway = bus_gateway
      @summary_use_case = summary_use_case
      @domestic_digest_gateway = domestic_digest_gateway
    end

    def execute(rrn:)
      bus_details = @bus_gateway.search_by_rrn(rrn)
      return nil if bus_details.nil?

      assessment_summary = @summary_use_case.execute(rrn)
      return nil if assessment_summary.nil?

      domestic_digest = @domestic_digest_gateway.fetch_by_rrn(rrn)

      assessment_details = Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
        domestic_digest:,
      )

      later_rrn = assessment_summary[:superseded_by]

      later_rrn ? Domain::AssessmentReference.new(rrn: later_rrn) : assessment_details
    end
  end
end
