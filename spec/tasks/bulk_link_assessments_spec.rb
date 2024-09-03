describe "bulk link assessments rake" do
  include RSpecRegisterApiServiceMixin

  let(:bulk_link_assessments) { get_task("maintenance:bulk_link_assessments") }
  let(:bulk_link_assessments_use_case) { instance_double(UseCase::BulkLinkAssessments) }
  let(:fetch_address_id_update_stats) { instance_double(UseCase::FetchAddressIdUpdateStats) }
  let(:text) { "This week: 1 groups of addresses were linked, 2 address ids were updated" }
  let(:webhook_url) { "https://slackurl.com" }

  before do
    EnvironmentStub.with("EPB_TEAM_SLACK_URL", webhook_url)
    allow(ApiFactory).to receive_messages(bulk_link_assessments_use_case:, fetch_address_id_update_stats:)
    allow(bulk_link_assessments_use_case).to receive(:execute)
    allow(fetch_address_id_update_stats).to receive(:execute).and_return(text)
    allow(Helper::SlackHelper).to receive(:post_to_slack)
    Timecop.freeze(2024, 12, 22, 0, 0, 0)
  end

  it "calls the bulk linking use case" do
    bulk_link_assessments.invoke
    expect(bulk_link_assessments_use_case).to have_received(:execute)
  end

  it "posts the results to Slack" do
    bulk_link_assessments.invoke
    expect(Helper::SlackHelper).to have_received(:post_to_slack).with(text:, webhook_url:)
    expect(fetch_address_id_update_stats).to have_received(:execute).with("2024-12-22")
  end
end
