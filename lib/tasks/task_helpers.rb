require "sentry-ruby"

module Tasks
  module TaskHelpers
    def self.quit_if_production
      if !ENV["STAGE"].nil? && !(%w[test development integration staging].include? ENV["STAGE"])
        raise StandardError, "This task can only be run if the STAGE is test, development, integration or staging"
      end
    end

    def self.get_last_months_dates
      end_date = Date.today.strftime("%Y-%m-01")
      start_date = Date.yesterday.strftime("%Y-%m-01")

      { start_date:, end_date: }
    end

    def self.initialize_sentry
      Sentry.init do |config|
        config.dsn = ENV["SENTRY_DSN"]
        config.breadcrumbs_logger = %i[sentry_logger http_logger]

        # To activate performance monitoring, set one of these options.
        # We recommend adjusting the value in production:
        config.traces_sample_rate = 1.0
      end
    end
  end
end
