# frozen_string_literal: true

module Gateway
  class RedisGateway
    attr_reader :redis

    def initialize(redis_client: nil)
      @redis = redis_client || Redis.new
    end

    def push_to_queue(queue_name, assessment_id)
      redis.lpush(queue_name, assessment_id)
    end
  end
end
