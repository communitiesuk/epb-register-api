module UseCase
  class FindAssessmentsForBusByUprn
    include Helper::DomesticDigestHelper
    def initialize(bus_gateway:, summary_use_case:, domestic_digest_gateway:)
      @bus_gateway = bus_gateway
      @summary_use_case = summary_use_case
      @domestic_digest_gateway = domestic_digest_gateway
    end

    def execute(uprn:)
      bus_details = @bus_gateway.search_by_uprn(uprn)
      return nil if bus_details.nil?

      bus_details = bus_details.first

      assessment_summary = @summary_use_case.execute(bus_details["epc_rrn"])
      return nil if assessment_summary.nil?
      rrn = bus_details["epc_rrn"]
      domestic_digest = get_domestic_digest(rrn: rrn)

      Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
        domestic_digest:,
      )
    end

    private

    attr_reader :domestic_digest_gateway
  end
end
