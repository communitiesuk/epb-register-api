require_relative "../../acceptance/reporting/open_data_export_test_helper"
require "sentry-ruby"

describe Worker::RecommendationsOpenDataExport do
  describe "#perform" do
    context "when there is data to send" do
      before do
        allow(Worker::OpenDataExportHelper).to receive(:call_rake)
      end

      it "executes the rake which calls the use case" do
        expect { described_class.new.perform }.not_to raise_error
      end

      it "calls rake with the correct arguments", :aggregate_failures do
        described_class.new.perform
        expect(Worker::OpenDataExportHelper).to have_received(:call_rake).with("CEPC-RR").exactly(1).times
        expect(Worker::OpenDataExportHelper).to have_received(:call_rake).with("DEC-RR").exactly(1).times
        expect(Worker::OpenDataExportHelper).to have_received(:call_rake).with("SAP-RDSAP-RR").exactly(1).times
        expect(Worker::OpenDataExportHelper).to have_received(:call_rake).exactly(3).times
      end
    end
  end
end
