describe Gateway::DataWarehouseRedisHelper do
  context "when application is not running on PaaS and Redis URI is not set in an environment variable" do
    before do
      allow(Helper::Platform).to receive(:is_paas?).and_return(false)
    end

    let(:redis) { described_class.redis }

    it "provides a redis client object that does not have class of Redis" do
      expect(redis).not_to be_a Redis
    end

    it "provides a redis client that can have RRNs pushed onto a list without erroring and resulting in a zero length list" do
      list_key = "rrn_list"
      expect { redis.lpush(list_key, %w[0000-0000-0000-0000-1111 1111-2222-3333-4444-5555]) }.not_to raise_error
      expect(redis.llen(list_key)).to eq 0
    end

    it "provides a redis client that can have report names added to a set on it" do
      expect { redis.sadd(:fake_set, %w[report_1 report_2]) }.not_to raise_error
    end

    it "provides a redis client that returns a hash for the hgetall method" do
      expect(redis.hgetall(:some_hash)).to eq({})
    end
  end
end
