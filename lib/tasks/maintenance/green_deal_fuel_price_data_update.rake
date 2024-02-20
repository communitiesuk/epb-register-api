# New fuel price data is published every 6 months (in June and December)
# This data is used to calculate the savings from Green Deal measures, and so
# this rake needs to be run every 6 months so we have the latest fuel prices in
# the register database.
namespace :maintenance do
  desc "Import up-to-date data for Green Deal fuel prices"
  task :green_deal_update_fuel_data do
    ApiFactory.import_green_deal_fuel_price_use_case.execute
  rescue UseCase::ImportGreenDealFuelPrice::NoDataException
    text = ":alert_slow No Fuel Price data available from www.ncm-pcdb.org.uk"
    webhook_url = ENV["EPB_TEAM_SLACK_URL"]
    Helper::SlackHelper.post_to_slack(text:, webhook_url:)
    raise
  end
end
