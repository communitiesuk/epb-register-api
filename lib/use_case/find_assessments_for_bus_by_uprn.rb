module UseCase
  class FindAssessmentsForBusByUprn
    def initialize(bus_gateway:, summary_use_case:)
      @bus_gateway = bus_gateway
      @summary_use_case = summary_use_case
    end

    def execute(uprn:)
      bus_details = @bus_gateway.search_by_uprn(uprn)
      return nil if bus_details.nil?

      bus_details = bus_details.first

      assessment_summary = @summary_use_case.execute(bus_details["epc_rrn"])
      return nil if assessment_summary.nil?

      Domain::AssessmentBusDetails.new(
        bus_details:,
        assessment_summary:,
      )
    end
  end
end
