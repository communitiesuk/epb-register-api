require 'date'

namespace :maintenance do
  desc "post weekly address id update stats to slack channel"
  task :post_updated_address_id_stats do
    yesterday =  ENV["DAY_DATE"] || Date.today.prev_day.strftime("%Y-%m-%d")
    text = ApiFactory.fetch_address_id_update_stats.execute(yesterday)
    webhook_url = ENV["EPB_TEAM_SLACK_URL"]
    Helper::SlackHelper.post_to_slack(text:, webhook_url:)
  end
end
