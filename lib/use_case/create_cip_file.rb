module UseCase
  class CreateCipFile

    def initialize(storage_gateway)
      @storage_gateway = storage_gateway
    end

    def execute
      file_names = @storage_gateway.read_degrees_day_data
      file_names.select { |file| file !~ /Scotland/}
    end

  end
end
