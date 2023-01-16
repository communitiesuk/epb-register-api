RSpec.describe Worker::ImportGreenDealFuelPriceData do
  describe "#perform" do
    let(:import_fuel_use_case) { instance_double(UseCase::ImportGreenDealFuelPrice) }

    before do
      allow($stdout).to receive(:puts)
    end

    context "when the workers run without error" do
      before do
        allow(ApiFactory).to receive(:import_green_deal_fuel_price_use_case).and_return(import_fuel_use_case)
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(import_fuel_use_case).to receive(:execute)
      end

      it "executes the rake which calls the use case" do
        expect { described_class.new.perform }.not_to raise_error
        expect(import_fuel_use_case).to have_received(:execute).exactly(1).times
      end
    end

    context "when the rake raises an error" do
      before do
        allow(ApiFactory).to receive(:import_green_deal_fuel_price_use_case).and_return(import_fuel_use_case)
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(import_fuel_use_case).to receive(:execute).and_raise UseCase::ImportGreenDealFuelPrice::NoDataException
      end

      it "posts the error to slack" do
        described_class.new.perform
        expect(Worker::SlackNotification).to have_received(:perform_async).exactly(1).times
      end
    end
  end
end
