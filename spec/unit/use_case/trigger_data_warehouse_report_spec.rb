# frozen_string_literal: true

describe UseCase::TriggerDataWarehouseReport do
  subject(:use_case) { described_class.new reports_gateway: }

  let(:reports_gateway) do
    gateway = instance_double Gateway::DataWarehouseReportsGateway
    allow(gateway).to receive(:write_trigger)
    gateway
  end

  it "calls down onto the reports gateway to write the trigger" do
    report = :count_of_the_sheep
    use_case.execute(report:)
    expect(reports_gateway).to have_received(:write_trigger)
  end
end
