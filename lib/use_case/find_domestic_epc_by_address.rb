module UseCase
  class FindDomesticEpcByAddress
    def initialize(gateway:)
      @gateway = gateway
    end

    def execute(postcode:, building_identifier:)
      { assessments:
          @gateway.fetch_by_address(postcode: postcode, building_identifier: building_identifier) }
    end
  end
end
