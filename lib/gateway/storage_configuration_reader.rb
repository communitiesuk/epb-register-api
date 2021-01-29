module Gateway
  class StorageConfigurationReader
    class IllegalCalLException < StandardError
    end

    def get_paas_configuration(instance_name)
      if ENV["VCAP_SERVICES"].nil?
        raise IllegalCalLException,
              "No VCAP_SERVICES environment variable present"
      end
      credentials_from_vcap_services instance_name
    end

    def get_local_configuration(bucket_name)
      if ENV["AWS_ACCESS_KEY_ID"].nil? && ENV["AWS_SECRET_ACCESS_KEY"].nil?
        raise IllegalCalLException,
              "No AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables present"
      end
      credentials_from_environment_variables bucket_name
    end

  private

    def credentials_from_environment_variables(bucket_name)
      Gateway::StorageConfiguration.new(
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        bucket_name: bucket_name,
      )
    end

    def credentials_from_vcap_services(instance_name)
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
