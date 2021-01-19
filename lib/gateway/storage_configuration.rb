module Gateway
  class StorageConfiguration
    attr_reader :access_key_id, :secret_access_key, :bucket_name

    def initialize(access_key_id:, secret_access_key:, bucket_name:)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket_name = bucket_name
    end

  end
end
