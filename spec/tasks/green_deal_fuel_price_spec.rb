require "rspec"

describe "rake maintenance:green_deal_update_fuel_data" do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { instance_double(UseCase::ImportGreenDealFuelPrice) }
  let(:gateway) { instance_double(Gateway::GreenDealFuelPriceGateway) }
  let(:update_rake_task) do
    get_task("maintenance:green_deal_update_fuel_data")
  end

  before do
    WebMock.enable!
    allow(ApiFactory).to receive(:import_green_deal_fuel_price_use_case).and_return(use_case)
    allow(Gateway::GreenDealFuelPriceGateway).to receive(:new).and_return(gateway)
    allow(use_case).to receive(:execute)
  end

  after do
    WebMock.disable!
  end

  context "when calling the rake" do
    it "calls the use case to make the request" do
      update_rake_task.invoke
      expect(use_case).to have_received(:execute).exactly(1).times
    ensure
      update_rake_task.reenable
    end
  end

  context "when the rake raises errors" do
    before do
      EnvironmentStub.with("EPB_TEAM_SLACK_URL", "https://slackurl.com")
      allow(use_case).to receive(:execute).and_raise UseCase::ImportGreenDealFuelPrice::NoDataException
      allow(Helper::SlackHelper).to receive(:post_to_slack)
    end

    after do
      EnvironmentStub.remove(%w[EPB_TEAM_SLACK_URL])
    end

    it "posts the error to Slack" do
      expect { update_rake_task.invoke }.to raise_error UseCase::ImportGreenDealFuelPrice::NoDataException
      expect(Helper::SlackHelper).to have_received(:post_to_slack).with({ text: ":alert_slow No Fuel Price data available from www.ncm-pcdb.org.uk", webhook_url: "https://slackurl.com" }).exactly(1).times
    ensure
      update_rake_task.reenable
    end
  end
end
