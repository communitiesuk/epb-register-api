module UseCase
  class FetchAssessmentForBus
    include Helper::DomesticDigestHelper
    class InvalidAssessmentTypeException < StandardError
    end

    def initialize(bus_gateway:, summary_use_case:, domestic_digest_gateway:)
      @bus_gateway = bus_gateway
      @summary_use_case = summary_use_case
      @domestic_digest_gateway = domestic_digest_gateway
    end

    def execute(rrn:)
      bus_details = @bus_gateway.search_by_rrn(rrn)
      return nil if bus_details.nil?

      raise InvalidAssessmentTypeException unless %w[RdSAP SAP CEPC].include? bus_details["report_type"]

      assessment_summary = @summary_use_case.execute(rrn)
      return nil if assessment_summary.nil?
      domestic_digest = get_domestic_digest(rrn:)

      assessment_details = Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
        domestic_digest:,
      )

      later_rrn = assessment_summary[:superseded_by]

      later_rrn ? Domain::AssessmentReference.new(rrn: later_rrn) : assessment_details
    end

    private

    attr_reader :domestic_digest_gateway
  end
end
