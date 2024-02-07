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
  end
end
