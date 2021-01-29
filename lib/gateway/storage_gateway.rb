module Gateway
  class StorageGateway
    attr_reader :storage_config, :client

    def initialize(storage_config:, stub_responses: false)
      @storage_config = storage_config
      @client = if stub_responses
                  initialise_client_stub
                else
                  initialise_client
                end
    end

    def get_file_io(file_name)
      file_response =
        client.get_object(bucket: storage_config.bucket_name, key: file_name)
      file_response.body
    end

  private

    def initialise_client
      credentials =
        Aws::Credentials.new(
          storage_config.access_key_id,
          storage_config.secret_access_key,
        )
      Aws::S3::Client.new(
        region: storage_config.region_name,
        credentials: credentials,
      )
    end

    def initialise_client_stub
      Aws::S3::Client.new(stub_responses: true)
    end
  end
end
