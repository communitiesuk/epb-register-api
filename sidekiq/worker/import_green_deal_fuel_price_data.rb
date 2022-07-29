require_relative "./worker_helpers"

module Worker
  class ImportGreenDealFuelPriceData
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      rake_task("maintenance:green_deal_update_fuel_data").invoke
    rescue UseCase::ImportGreenDealFuelPrice::NoDataException
      message = ":alert_slow No Fuel Price data available from www.boilers.org.uk"
      Worker::SlackNotification.perform_async(message)
      puts message
    end
  end
end
