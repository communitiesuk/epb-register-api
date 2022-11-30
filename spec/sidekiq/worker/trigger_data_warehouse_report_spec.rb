# frozen_string_literal: true

describe Worker::TriggerDataWarehouseReport do
  subject(:worker) { described_class.new }

  let(:trigger_report_use_case) do
    use_case = instance_double UseCase::TriggerDataWarehouseReport
    allow(use_case).to receive(:execute)
    use_case
  end

  before do
    allow(UseCase::TriggerDataWarehouseReport).to receive(:new).and_return(trigger_report_use_case)
    allow(Helper::Toggles).to receive(:enabled?).with("register-api-triggers-reports").and_yield
  end

  describe "#perform" do
    reports = %i[this_report that_report]

    before do
      worker.perform(*reports)
    end

    it "calls down onto the trigger report use case for each of the reports" do
      count = 0
      expect(trigger_report_use_case).to have_received(:execute).twice do |report:|
        expect(report).to eq(reports[count])
        count += 1
      end
    end
  end

  it "is a sidekiq worker" do
    expect(worker).to be_a_kind_of Sidekiq::Worker
  end
end
