# frozen_string_literal: true

describe UseCase::FetchDataWarehouseReports do
  subject(:use_case) { described_class.new reports_gateway: }

  let(:reports_gateway) { instance_double Gateway::DataWarehouseReportsGateway }

  before do
    allow(reports_gateway).to receive(:write_triggers)
  end

  context "when the gateway returns a complete report collection" do
    let(:reports) do
      Domain::DataWarehouseReportCollection.new
    end

    before do
      allow(reports_gateway).to receive(:reports).and_return(reports)
    end

    it "returns the reports from the gateway without modification" do
      expect(use_case.execute).to be reports
    end

    it "does not try and write triggers through the gateway" do
      use_case.execute
      expect(reports_gateway).not_to have_received(:write_triggers)
    end
  end

  context "when the gateway returns an incomplete report collection" do
    let(:reports) do
      Domain::DataWarehouseReportCollection.new(
        Domain::DataWarehouseReport.new(name: :known_report_1, data: 56, generated_at: "2022-12-20T12:07:00Z"),
        Domain::DataWarehouseReport.new(name: :known_report_3, data: 147, generated_at: "2022-12-20T12:07:03Z"),
        incomplete: true,
      )
    end

    before do
      allow(reports_gateway).to receive(:known_reports).and_return(%i[known_report_1 known_report_2 known_report_3])
      allow(reports_gateway).to receive(:reports).and_return(reports)
    end

    it "returns the reports from the gateway without modification" do
      expect(use_case.execute).to be reports
    end

    it "requests writing of triggers for missing reports through the gateway" do
      use_case.execute
      expect(reports_gateway).to have_received(:write_triggers).with(reports: [:known_report_2])
    end
  end
end
