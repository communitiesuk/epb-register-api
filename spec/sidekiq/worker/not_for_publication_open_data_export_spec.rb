require_relative "../../acceptance/reporting/open_data_export_test_helper"
require "sentry-ruby"

RSpec.describe Worker::NotForPublicationOpenDataExport do
  describe "#perform" do
    context "when there is data to send" do
      before do
        allow(Worker::OpenDataExportHelper).to receive(:call_rake)
      end

      it "executes the rake which calls the use case" do
        expect { described_class.new.perform }.not_to raise_error
      end

      it "calls rake with correct arguments" do
        described_class.new.perform
        expect(Worker::OpenDataExportHelper).to have_received(:call_rake).with(rake_name: "open_data:export_not_for_publication").exactly(1).times
      end
    end

    context "when there is no data to send" do
      before do
        allow(Worker::OpenDataExportHelper).to receive(:call_rake).and_raise(Boundary::OpenDataEmpty)
        allow(Sentry).to receive(:capture_exception)
      end

      it "send the error to sentry" do
        described_class.new.perform
        expect(Sentry).to have_received(:capture_exception).with(Boundary::OpenDataEmpty)
      end
    end
  end
end
