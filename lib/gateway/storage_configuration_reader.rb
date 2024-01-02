module Gateway
  class StorageConfigurationReader
    attr_reader :bucket_name

    class IllegalCallException < StandardError
    end

    def initialize(bucket_name: nil)
      @bucket_name = bucket_name
    end

    def get_configuration
      if aws_ecs_specific_configuration?
        credentials_for_ecs
      elsif local_configuration?
        credentials_from_local_keys
      else
        raise IllegalCallException,
              "Local or AWS credentials not present"
      end
    end

  private

    def local_configuration?
      !ENV["AWS_ACCESS_KEY_ID"].nil? && !ENV["AWS_SECRET_ACCESS_KEY"].nil? &&
        !bucket_name.nil?
    end

    def aws_ecs_specific_configuration?
      ENV["AWS_ACCESS_KEY_ID"].nil? &&
        ENV["AWS_SECRET_ACCESS_KEY"].nil? && # ECS will not make these environment variables available
        !ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"].nil? && # env var available on AWS ECS instances
        !ENV["AWS_EXECUTION_ENV"].nil? &&
        ENV["AWS_EXECUTION_ENV"].include?("ECS") &&
        !bucket_name.nil?
    end

    def credentials_from_local_keys
      Gateway::StorageConfiguration.new(
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        bucket_name:,
      )
    end

    def credentials_for_ecs
      Gateway::StorageConfiguration.new bucket_name:,
                                        credentials: Aws::ECSCredentials.new
    end
  end
end
