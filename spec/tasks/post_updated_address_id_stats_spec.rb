require "rspec"

describe "post weekly address id update stats rake" do
  include RSpecRegisterApiServiceMixin
  let(:post_updated_address_id_stats) { get_task("maintenance:post_updated_address_id_stats") }

  let(:fetch_address_id_update_stats) { instance_double(UseCase::FetchAddressIdUpdateStats) }
  let(:text) { "This week: 1 groups of addresses were linked, 2 address ids were updated" }
  let(:webhook_url) { "https://slackurl.com" }

  before do
    EnvironmentStub.with("EPB_TEAM_SLACK_URL", webhook_url)
    allow(ApiFactory).to receive(:fetch_address_id_update_stats).and_return(fetch_address_id_update_stats)
    allow(fetch_address_id_update_stats).to receive(:execute).and_return(text)
    allow(Helper::SlackHelper).to receive(:post_to_slack)
    post_updated_address_id_stats.invoke
  end

  after do
    EnvironmentStub.remove(%w[EPB_TEAM_SLACK_URL])
  end

  context "when calling the rake" do
    it "posts the results to Slack" do
      expect(fetch_address_id_update_stats).to have_received(:execute)
      expect(Helper::SlackHelper).to have_received(:post_to_slack).with(text:, webhook_url:)
    end
  end
end
