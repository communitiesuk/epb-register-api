# frozen_string_literal: true

require "redis"

module Gateway
  class RedisGateway
    class PushFailedError < StandardError; end

    class InvalidRedisQueueNameError < StandardError; end

    QUEUE_NAMES = %i[assessments cancelled opt-outs].freeze

    @redis_client_class = Redis

    def initialize(redis_client: nil)
      @redis = redis_client
    end

    def push_to_queue(queue_name, assessment_id)
      validate_queue_name(queue_name.to_sym)
      redis.lpush(queue_name.to_s, assessment_id)
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

      @redis = self.class.redis_client_class.new
    end

    def validate_queue_name(name)
      raise InvalidRedisQueueNameError, "You can only accress #{QUEUE_NAMES}" unless valid_queue_name?(name)
    end

    def valid_queue_name?(name)
      QUEUE_NAMES.include?(name)
    end
  end
end
