# frozen_string_literal: true

describe "fetching interesting numbers" do
  include RSpecRegisterApiServiceMixin

  let(:redis) { MockRedis.new }

  before do
    stub_const("Gateway::DataWarehouseReportsGateway::REPORTS", %w[known_report_1 known_report_2])
    Gateway::DataWarehouseReportsGateway.redis_client_class = MockRedis
    mock_redis = redis
    allow(MockRedis).to receive(:new).and_return mock_redis
  end

  after { redis.flushdb }

  context "when calling the interesting numbers endpoint" do
    context "when all known interesting numbers/ reports are in the store" do
      let(:reports) do
        {
          known_report_1: { data: 42, date_created: "2022-12-16T15:52:30Z" },
          known_report_2: { data: [{ month: 1, count: 56 }, { month: 2, count: 94 }], date_created: "2022-12-16T14:32:48Z" },
        }
      end

      before do
        stub_const "Gateway::DataWarehouseReportsGateway::REPORTS", %i[known_report_1 known_report_2]
        redis.hset :reports, *reports.transform_values(&:to_json).to_a.flatten
      end

      it "responds with a 200 and the data in expected format" do
        response = fetch_interesting_numbers
        expect(response.status).to eq 200
        expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq([
          {
            name: "known_report_1",
            data: 42,
            generatedAt: "2022-12-16T15:52:30Z",
          },
          {
            name: "known_report_2",
            data: [{ month: 1, count: 56 }, { month: 2, count: 94 }],
            generatedAt: "2022-12-16T14:32:48Z",
          },
        ])
      end
    end

    context "when not all known interesting numbers/ reports are in the store" do
      let(:reports) do
        {
          known_report_2: { data: [{ month: 1, count: 56 }, { month: 2, count: 94 }], date_created: "2022-12-16T14:32:48Z" },
        }
      end

      let(:response) { fetch_interesting_numbers accepted_responses: [202] }

      before do
        stub_const "Gateway::DataWarehouseReportsGateway::REPORTS", %i[known_report_1 known_report_2]
        redis.hset :reports, *reports.transform_values(&:to_json).to_a.flatten
      end

      it "responds with a 202 and the data in expected format" do
        expect(response.status).to eq 202
        expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq([
          {
            name: "known_report_2",
            data: [{ month: 1, count: 56 }, { month: 2, count: 94 }],
            generatedAt: "2022-12-16T14:32:48Z",
          },
        ])
      end

      it "has made sure there is a trigger sent to the data warehouse for the missing report" do
        response
        expect(redis.smembers(:report_triggers)).to include "known_report_1"
      end
    end
  end
end
