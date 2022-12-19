# frozen_string_literal: true

describe UseCase::TriggerAllDataWarehouseReports do
  subject(:use_case) { described_class.new(reports_gateway:) }

  let(:reports_gateway) do
    gateway = instance_double Gateway::DataWarehouseReportsGateway
    allow(gateway).to receive(:write_all_triggers)
    gateway
  end

  before do
    use_case.execute
  end

  it "calls down to the reports gateway" do
    expect(reports_gateway).to have_received(:write_all_triggers)
  end
end
