# frozen_string_literal: true

require "redis"

module Gateway
  class DataWarehouseRedisHelper
    @redis_client_class = Redis

    def self.redis
      if ENV.key?("EPB_DATA_WAREHOUSE_QUEUES_URI")
        redis_url = ENV["EPB_DATA_WAREHOUSE_QUEUES_URI"]
      elsif !Helper::Platform.is_paas?
        return fake_redis
      else
        redis_instance_name = "dluhc-epb-redis-data-warehouse-#{ENV['STAGE']}"
        redis_url = RedisConfigurationReader.configuration_url(redis_instance_name)
      end

      redis_client_class.new(url: redis_url)
    end

    def self.fake_redis
      redis = Object.new
      class << redis
        def method_missing(command, *_args, **_kwargs)
          return {} if command.to_sym == :hgetall

          command.to_s.include?("len") ? 0 : []
        end

        def respond_to_missing?(...)
          true
        end

        def method_defined?(...)
          true
        end
      end

      redis
    end

    class << self
      attr_writer :redis_client_class
    end

    class << self
      attr_reader :redis_client_class
    end

    private_class_method :fake_redis
  end
end
