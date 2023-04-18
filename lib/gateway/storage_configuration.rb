module Gateway
  class StorageConfiguration
    attr_reader :bucket_name, :region_name

    def initialize(
      bucket_name:,
      access_key_id: nil,
      secret_access_key: nil,
      credentials: nil,
      region_name: "eu-west-2"
    )
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @credentials_object = credentials
      @bucket_name = bucket_name
      @region_name = region_name
    end

    def credentials?
      credentials_object? || static_credentials?
    end

    def credentials
      return nil unless credentials?

      credentials_object || Aws::Credentials.new(access_key_id, secret_access_key)
    end

  private

    def static_credentials?
      !access_key_id.nil? && !secret_access_key.nil?
    end

    def credentials_object?
      !credentials_object.nil?
    end

    attr_reader :access_key_id, :secret_access_key, :credentials_object
  end
end
