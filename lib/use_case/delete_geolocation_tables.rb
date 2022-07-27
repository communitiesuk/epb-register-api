module UseCase
  class DeleteGeolocationTables
    def initialize(geolocation_gateway)
      @geolocation_gateway = geolocation_gateway
    end

    def execute
      @geolocation_gateway.clean_up
    end
  end
end
