module Gateway
  class StorageConfiguration
    attr_reader :access_key_id, :secret_access_key, :bucket_name, :region_name

    def initialize(access_key_id:, secret_access_key:, bucket_name:, region_name: 'eu-west-2')
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket_name = bucket_name
      @region_name = region_name
    end

  end
end
