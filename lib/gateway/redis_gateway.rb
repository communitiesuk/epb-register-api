# frozen_string_literal: true

require "redis"

module Gateway
  class RedisGateway
    class PushFailedError < StandardError; end

    class InvalidRedisQueueNameError < StandardError; end

    DATA_WAREHOUSE_QUEUES = %i[assessments cancelled opt_outs].freeze

    @redis_client_class = Redis

    def initialize(redis_client: nil)
      @redis = redis_client
    end

    def push_to_queue(queue_name, assessment_ids)
      validate_queue_name(queue_name.to_sym)
      redis.lpush(queue_name.to_s, assessment_ids)
    rescue Redis::BaseError => e
      raise PushFailedError, "Got Redis error #{e.class} when pushing to the queue: #{e.message}"
    end

    class << self
      attr_writer :redis_client_class
    end

    class << self
      attr_reader :redis_client_class
    end

  private

    def redis
      return @redis if @redis

      if ENV.key?("EPB_DATA_WAREHOUSE_QUEUES_URI")
        redis_url = ENV["EPB_DATA_WAREHOUSE_QUEUES_URI"]
      else
        redis_instance_name = "dluhc-epb-redis-data-warehouse-#{ENV['STAGE']}"
        redis_url = RedisConfigurationReader.configuration_url(redis_instance_name)
      end

      @redis = self.class.redis_client_class.new(url: redis_url)
    end

    def validate_queue_name(name)
      raise InvalidRedisQueueNameError, "You can only access #{DATA_WAREHOUSE_QUEUES}" unless valid_queue_name?(name)
    end

    def valid_queue_name?(name)
      DATA_WAREHOUSE_QUEUES.include?(name)
    end
  end
end
