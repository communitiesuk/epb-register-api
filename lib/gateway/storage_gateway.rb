require 'aws-sdk-s3'

module Gateway
  class StorageGateway

    def initialize(storage_config:)
      @storage_configuration = storage_config
      @s3_client = initialize_client
    end

    def get_file_io(file_name:)
      file_response = s3_client.get_object(bucket: storage_configuration.bucket_name, key: file_name)
      file_response.body
    end

    private

    attr_reader :storage_configuration, :s3_client

    def initialize_client
      s3_credentials = Aws::Credentials.new(storage_configuration.access_key_id, storage_configuration.secret_access_key)
      Aws::S3::Client.new(credentials: s3_credentials)
    end

  end
end
