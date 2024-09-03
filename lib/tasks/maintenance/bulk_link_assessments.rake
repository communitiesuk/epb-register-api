# select all private subnets (but not the private-db subnets) when running the task in the console to ensure data warehouse is updated
namespace :maintenance do
  desc "Link non domestic "
  task :bulk_link_assessments do
    bulk_linking_use_case = ApiFactory.bulk_link_assessments_use_case
    bulk_linking_use_case.execute

    today = Date.today.strftime("%Y-%m-%d")
    text = ApiFactory.fetch_address_id_update_stats.execute(today)
    webhook_url = ENV["EPB_TEAM_SLACK_URL"]
    Helper::SlackHelper.post_to_slack(text:, webhook_url:)
  end
end
