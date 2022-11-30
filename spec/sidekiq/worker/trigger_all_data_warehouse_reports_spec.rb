# frozen_string_literal: true

describe Worker::TriggerAllDataWarehouseReports do
  subject(:worker) { described_class.new }

  let(:trigger_all_reports_use_case) do
    use_case = instance_double UseCase::TriggerAllDataWarehouseReports
    allow(use_case).to receive(:execute)
    use_case
  end

  before do
    allow(UseCase::TriggerAllDataWarehouseReports).to receive(:new).and_return(trigger_all_reports_use_case)
    allow(Helper::Toggles).to receive(:enabled?).with("register-api-triggers-reports").and_yield
  end

  describe "#perform" do
    before do
      worker.perform
    end

    it "calls down onto the trigger all use case" do
      expect(trigger_all_reports_use_case).to have_received(:execute)
    end
  end

  it "is a sidekiq worker" do
    expect(worker).to be_a_kind_of Sidekiq::Worker
  end
end
