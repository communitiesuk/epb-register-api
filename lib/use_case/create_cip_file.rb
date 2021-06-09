module UseCase
  class CreateCipFile
    class NoFiles < StandardError
    end

    def initialize(storage_gateway)
      @storage_gateway = storage_gateway
    end

    def execute
      file_names = @storage_gateway.read_degrees_day_data

      raise NoFiles if file_names.empty?

      file_names.select { |file| file !~ /Scotland/ }
    end
  end
end
