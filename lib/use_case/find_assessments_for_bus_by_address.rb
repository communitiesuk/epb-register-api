module UseCase
  class FindAssessmentsForBusByAddress
    def initialize(bus_gateway:, summary_use_case:)
      @bus_gateway = bus_gateway
      @summary_use_case = summary_use_case
    end

    def execute(postcode:, building_identifier:)
      bus_details = @bus_gateway.search_by_postcode_and_building_identifier(
        postcode:,
        building_identifier:,
      )
      return nil if bus_details.nil?

      details_list = bus_details.map do |bus_detail|
        assessment_summary = @summary_use_case.execute(bus_detail["epc_rrn"])
        return nil if assessment_summary.nil?

        Domain::AssessmentBusDetails.new(
          bus_details: bus_detail,
          assessment_summary:,
        )
      end

      case details_list.count
      when 0
        nil
      when 1
        details_list.first
      else
        Domain::AssessmentReferenceList.new(*details_list.map(&:rrn))
      end
    end
  end
end
