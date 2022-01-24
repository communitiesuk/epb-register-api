module Worker
  class PostPreviousDayStatisticsToSlack
    include Sidekiq::Worker

    sidekiq_options retry: 1

    def perform
      message = ApiFactory.format_daily_stats_for_slack_use_case.execute

      Worker::SlackNotification.perform_async(message)
    end
  end
end
