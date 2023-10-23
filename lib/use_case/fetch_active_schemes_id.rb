module UseCase
  class FetchActiveSchemesId
    def initialize(schemes_gateway)
      @schemes_gateway = schemes_gateway || Gateway::SchemesGateway.new
    end

    def execute
      @schemes_gateway.fetch_active
    end
  end
end
