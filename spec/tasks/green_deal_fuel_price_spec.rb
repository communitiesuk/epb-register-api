require "rspec"

describe "rake maintenance:green_deal_update_fuel_data" do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { instance_double(UseCase::ImportGreenDealFuelPrice) }

  before do
    allow(ApiFactory).to receive(:import_green_deal_fuel_price_use_case).and_return(use_case)
    allow(use_case).to receive(:execute)
  end

  context "when calling the rake " do
    it "calls the use case to make the request" do
      get_task("maintenance:green_deal_update_fuel_data").invoke
      expect(use_case).to have_received(:execute).exactly(1).times
    end
  end
end
