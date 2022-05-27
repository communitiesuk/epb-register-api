module UseCase
  class FindAssessmentsForHeraByAddress
    def initialize(hera_gateway:)
      @hera_gateway = hera_gateway
    end

    def execute(postcode:, building_identifier:)
      { assessments:
        @hera_gateway.fetch_by_address(postcode: postcode, building_identifier: building_identifier) }
    end
  end
end
