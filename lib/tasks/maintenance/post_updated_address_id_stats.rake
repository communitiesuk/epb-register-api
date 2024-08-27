require 'date'

namespace :maintenance do
  desc "post weekly address id update stats to slack channel"
  task :post_updated_address_id_stats do
    yesterday = Date.today.prev_day
    text = ApiFactory.fetch_address_id_update_stats.execute(yesterday)
    webhook_url = ENV["EPB_TEAM_SLACK_URL"]
    Helper::SlackHelper.post_to_slack(text:, webhook_url:)
  end
end
