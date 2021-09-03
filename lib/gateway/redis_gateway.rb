# frozen_string_literal: true

require "redis"

module Gateway
  class RedisGateway
    @redis_client_class = Redis

    def initialize(redis_client: nil)
      @redis = redis_client
    end

    def push_to_queue(queue_name, assessment_id)
      redis.lpush(queue_name, assessment_id)
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
  end
end
