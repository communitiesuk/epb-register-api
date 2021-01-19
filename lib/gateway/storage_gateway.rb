module Gateway
  class StorageGateway

    def initialize(client:, storage_config:)
      @storage_configuration = storage_config
      @client = client
    end

    def get_file_io(file_name:)
      file_response = client.get_object(bucket: storage_configuration.bucket_name, key: file_name)
      file_response.body
    end

    private
    attr_reader :storage_configuration, :client

  end
end
