# frozen_string_literal: true

describe Gateway::DataWarehouseReportsGateway do
  subject(:gateway) { described_class.new(redis_client: redis) }

  let(:redis) { MockRedis.new }

  after { redis.flushdb }

  context "when writing a report trigger" do
    it "writes to the report triggers set on redis", aggregate_errors: true do
      expect(redis.smembers(:report_triggers)).to eq []
      report = :how_many_reticulated_splines
      gateway.write_trigger(report:)
      expect(redis.smembers(:report_triggers)).to eq [report].map(&:to_s)
    end
  end

  context "when writing several report triggers" do
    it "writes them all to the report triggers set on redis" do
      expect(redis.smembers(:report_triggers)).to eq []
      reports = %i[how_many_reticulated_splines monthly_spline_counts]
      gateway.write_triggers(reports:)
      expect(redis.smembers(:report_triggers)).to eq reports.map(&:to_s)
    end
  end

  context "when writing all reports" do
    let(:known_reports) { %i[my_report_1 my_report_2] }

    before do
      stub_const "#{described_class}::REPORTS", known_reports
    end

    it "writes to the report triggers set on redis" do
      gateway.write_all_triggers
      expect(redis.smembers(:report_triggers)).to eq known_reports.map(&:to_s)
    end
  end

  context "when reading reports" do
    context "when all reports exist in the store" do
      let(:reports) do
        {
          known_report_1: { data: 42, date_created: "2022-12-16T15:52:30Z" },
          known_report_2: { data: [{ month: 1, count: 56 }, { month: 2, count: 94 }], date_created: "2022-12-16T14:32:48Z" },
        }
      end

      let(:expected_hashed_reports) do
        [
          {
            name: :known_report_1,
            data: 42,
            generated_at: "2022-12-16T15:52:30Z",
          },
          {
            name: :known_report_2,
            data: [{ month: 1, count: 56 }, { month: 2, count: 94 }],
            generated_at: "2022-12-16T14:32:48Z",
          },
        ]
      end

      before do
        stub_const "#{described_class}::REPORTS", %i[known_report_1 known_report_2]
        redis.hset :reports, *reports.transform_values(&:to_json).to_a.flatten
      end

      it "returns the expected list of interesting numbers" do
        expect(gateway.reports.map(&:to_hash)).to eq expected_hashed_reports
      end

      it "is not incomplete" do
        expect(gateway.reports).not_to be_incomplete
      end
    end

    context "when only some reports exist in the store" do
      let(:reports) do
        {
          known_report_1: { data: 42, date_created: "2022-12-16T15:52:30Z" },
          known_report_3: { data: [{ month: 1, count: 56 }, { month: 2, count: 94 }], date_created: "2022-12-16T14:32:48Z" },
        }
      end

      let(:expected_hashed_reports) do
        [
          {
            name: :known_report_1,
            data: 42,
            generated_at: "2022-12-16T15:52:30Z",
          },
          {
            name: :known_report_3,
            data: [{ month: 1, count: 56 }, { month: 2, count: 94 }],
            generated_at: "2022-12-16T14:32:48Z",
          },
        ]
      end

      before do
        stub_const "#{described_class}::REPORTS", %i[known_report_1 known_report_2 known_report_3]
        redis.hset :reports, *reports.transform_values(&:to_json).to_a.flatten
      end

      it "returns an incomplete report collection" do
        expect(gateway.reports).to be_incomplete
      end
    end

    context "when reports do not exist in the store" do
      it "returns an empty list" do
        expect(gateway.reports.map(&:to_hash)).to eq []
      end
    end

    context "when fetching a list of known reports" do
      let(:actual_known_reports) { gateway.known_reports }

      let(:expected_known_reports) { %i[known_report_1 known_report_2 known_report_3] }

      before do
        stub_const "#{described_class}::REPORTS", expected_known_reports
      end

      it "provides the reports from the REPORTS constant" do
        expect(expected_known_reports).to eq actual_known_reports
      end
    end
  end
end
