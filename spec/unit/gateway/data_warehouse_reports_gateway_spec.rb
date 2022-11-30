# frozen_string_literal: true

describe Gateway::DataWarehouseReportsGateway do
  subject(:gateway) { described_class.new(redis_client: redis) }

  let(:redis) { MockRedis.new }

  after { redis.flushdb }

  context "when writing a report trigger" do
    it "writes to the reports set on redis", aggregate_errors: true do
      expect(redis.smembers(:report_triggers)).to eq []
      report = :how_many_reticulated_splines
      gateway.write_trigger(report:)
      expect(redis.smembers(:report_triggers)).to eq [report].map(&:to_s)
    end
  end
end
