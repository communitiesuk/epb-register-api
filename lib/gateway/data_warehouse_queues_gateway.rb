# frozen_string_literal: true

require "redis"

module Gateway
  class DataWarehouseQueuesGateway
    class PushFailedError < StandardError; end

    class InvalidRedisQueueNameError < StandardError; end

    DATA_WAREHOUSE_QUEUES = %i[assessments cancelled opt_outs assessments_address_update matched_address_update backfill_matched_address_update].freeze

    def initialize(redis_client: nil)
      @redis = redis_client
    end

    def push_to_queue(queue_name, payload)
      validate_queue_name(queue_name.to_sym)
      redis.lpush(queue_name.to_s, payload)
    rescue Redis::BaseError => e
      raise PushFailedError, "Got Redis error #{e.class} when pushing to the queue: #{e.message}"
    end

  private

    def redis
      return @redis if @redis

      @redis = DataWarehouseRedisHelper.redis
    end

    def validate_queue_name(name)
      raise InvalidRedisQueueNameError, "You can only access #{DATA_WAREHOUSE_QUEUES}" unless valid_queue_name?(name)
    end

    def valid_queue_name?(name)
      DATA_WAREHOUSE_QUEUES.include?(name)
    end
  end
end
