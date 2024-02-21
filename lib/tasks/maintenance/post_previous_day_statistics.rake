namespace :maintenance do
  desc "post daily statistics to slack channel"
  task :post_previous_day_statistics do
    text = ApiFactory.format_daily_stats_for_slack_use_case.execute
    webhook_url = ENV["EPB_TEAM_SLACK_URL"]
    Helper::SlackHelper.post_to_slack(text:, webhook_url:)
  end
end
