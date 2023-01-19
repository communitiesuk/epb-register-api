require "rspec"

describe "rake maintenance:green_deal_update_fuel_data" do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { instance_double(UseCase::ImportGreenDealFuelPrice) }
  let(:gateway) { instance_double(Gateway::GreenDealFuelPriceGateway) }

  before do
    WebMock.enable!
    allow(ApiFactory).to receive(:import_green_deal_fuel_price_use_case).and_return(use_case)
    allow(Gateway::GreenDealFuelPriceGateway).to receive(:new).and_return(gateway)
    allow(use_case).to receive(:execute)
  end

  after do
    WebMock.disable!
  end

  context "when calling the rake " do
    it "calls the use case to make the request" do
      update_rake_task = get_task("maintenance:green_deal_update_fuel_data")
      begin
        update_rake_task.invoke
        expect(use_case).to have_received(:execute).exactly(1).times
      ensure
        update_rake_task.reenable
      end
    end
  end
end
