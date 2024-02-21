require "rspec"

describe "post previous days statistics rake" do
  include RSpecRegisterApiServiceMixin
  let(:post_daily_statistics_rake) { get_task("maintenance:post_previous_day_statistics") }

  let(:format_daily_stats_for_slack_use_case) { instance_double(UseCase::FormatDailyStatsForSlack) }
  let(:text) { "The total of 150 assessments were lodged yesterday" }
  let(:webhook_url) { "https://slackurl.com" }

  before do
    EnvironmentStub.with("EPB_TEAM_SLACK_URL", webhook_url)
    allow(ApiFactory).to receive(:format_daily_stats_for_slack_use_case).and_return(format_daily_stats_for_slack_use_case)
    allow(format_daily_stats_for_slack_use_case).to receive(:execute).and_return(text)
    allow(Helper::SlackHelper).to receive(:post_to_slack)
    post_daily_statistics_rake.invoke
  end

  after do
    EnvironmentStub.remove(%w[EPB_TEAM_SLACK_URL])
  end

  context "when calling the rake" do
    it "posts the results to slack" do
      expect(format_daily_stats_for_slack_use_case).to have_received(:execute)
      expect(Helper::SlackHelper).to have_received(:post_to_slack).with(text:, webhook_url:)
    end
  end
end
