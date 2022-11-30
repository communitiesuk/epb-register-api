# frozen_string_literal: true

describe UseCase::TriggerAllDataWarehouseReports do
  subject(:use_case) { described_class.new(individual_use_case:) }

  let(:individual_use_case) do
    individual_use_case = instance_double UseCase::TriggerDataWarehouseReport
    allow(individual_use_case).to receive(:execute)
    individual_use_case
  end

  it "calls down to the individual use case for each known report" do
    use_case.execute
    count = 0
    expect(individual_use_case).to have_received(:execute).at_least(:once) do |report:|
      expect(report).to eq(described_class::REPORTS[count])
      count += 1
    end
  end
end
