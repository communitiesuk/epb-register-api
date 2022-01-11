describe Gateway::RedisGateway do
  subject(:gateway) { described_class.new(redis_client: redis) }

  let(:redis) { MockRedis.new }

  let(:ids) { %w[9999-0000-0000-0000-5444 9999-0000-0000-0000-4444] }

  after { redis.flushdb }

  describe ".push_to_queue" do
    it "can push multiple assessment IDs to an empty queue" do
      gateway.push_to_queue(:assessments, ids)

      expect(redis.lrange("assessments", 0, -1).reverse).to eq(ids)
    end

    it "can push a single assessment ID to an empty queue" do
      id = "9999-6666-7777-8888-9999"
      gateway.push_to_queue :assessments, id

      expect(redis.lrange("assessments", 0, -1)).to eq [id]
    end

    it "raises an error for an invalid queue name" do
      expect { gateway.push_to_queue(:none_exisitng_queue, ids) }.to raise_error(
        Gateway::RedisGateway::InvalidRedisQueueNameError,
      )
    end

    context "when there is an error is writing to Redis" do
      erroring_gateway = nil

      let(:exploding_redis) do
        exploding_redis = instance_double Redis
        allow(exploding_redis).to receive(:lpush) { raise Redis::CannotConnectError }

        exploding_redis
      end

      before do
        erroring_gateway = described_class.new(redis_client: exploding_redis)
      end

      it "raises a PushFailedError" do
        expect { erroring_gateway.push_to_queue(:assessments, ids) }.to raise_error Gateway::RedisGateway::PushFailedError
      end
    end
  end
end
