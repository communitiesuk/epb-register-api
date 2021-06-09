module UseCase
  class CreateCipFile

    def initialize(storage_gateway)
      @storage_gateway = storage_gateway
    end

    def execute
      @storage_gateway.read_degrees_day_data
    end

  end
end
