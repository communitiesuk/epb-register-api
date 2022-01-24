RSpec.describe Worker::PostPreviousDayStatisticsToSlack do
  describe "#perform" do
    let(:format_daily_stats_for_slack_use_case) { instance_double(UseCase::FormatDailyStatsForSlack) }

    before do
      allow(ApiFactory).to receive(:format_daily_stats_for_slack_use_case).and_return(format_daily_stats_for_slack_use_case)
      allow(format_daily_stats_for_slack_use_case).to receive(:execute).and_return("The total of 150 assessments were lodged yesterday")
      allow(Worker::SlackNotification).to receive(:perform_async)
    end

    it "calls the worker with a message" do
      described_class.new.perform

      expect(format_daily_stats_for_slack_use_case).to have_received(:execute)
      expect(Worker::SlackNotification).to have_received(:perform_async).with("The total of 150 assessments were lodged yesterday")
    end
  end
end
