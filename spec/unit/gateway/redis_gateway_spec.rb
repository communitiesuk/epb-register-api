describe Gateway::RedisGateway do
  subject(:gateway) { described_class.new(redis_client: redis) }

  let(:redis) { MockRedis.new }

  let(:ids) { %w[9999-0000-0000-0000-5444 9999-0000-0000-0000-4444] }

  after { redis.flushdb }

  describe ".push_to_queue" do
    it "can push assessment ids to an empty queue" do
      gateway.push_to_queue("assessments", ids)

      expect(gateway.redis.lrange("assessments", 0, -1).reverse).to eq(ids)
    end
  end
end
