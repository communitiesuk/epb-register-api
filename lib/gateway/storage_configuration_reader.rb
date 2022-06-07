module Gateway
  class StorageConfigurationReader
    attr_reader :instance_name, :bucket_name

    class IllegalCallException < StandardError
    end

    def initialize(instance_name: nil, bucket_name: nil)
      @instance_name = instance_name
      @bucket_name = bucket_name
    end

    def get_configuration
      if paas_configuration_present?
        credentials_from_vcap_services
      elsif local_configuration_present?
        credentials_from_local_keys
      else
        raise IllegalCallException,
              "Local AWS credentials or VCAP_SERVICES not present"
      end
    end

  private

    def local_configuration_present?
      !ENV["AWS_ACCESS_KEY_ID"].nil? && !ENV["AWS_SECRET_ACCESS_KEY"].nil? &&
        !bucket_name.nil?
    end

    def paas_configuration_present?
      !ENV["VCAP_SERVICES"].nil? && !instance_name.nil?
    end

    def credentials_from_local_keys
      Gateway::StorageConfiguration.new(
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        bucket_name:,
      )
    end

    def credentials_from_vcap_services
      vcap = JSON.parse(ENV["VCAP_SERVICES"])
      s3_bucket_configs = vcap["aws-s3-bucket"]
      s3_bucket_config =
        s3_bucket_configs.detect do |bucket|
          bucket["instance_name"] == instance_name
        end

      Gateway::StorageConfiguration.new(
        access_key_id: s3_bucket_config["credentials"]["aws_access_key_id"],
        secret_access_key:
          s3_bucket_config["credentials"]["aws_secret_access_key"],
        bucket_name: s3_bucket_config["credentials"]["bucket_name"],
      )
    end
  end
end
