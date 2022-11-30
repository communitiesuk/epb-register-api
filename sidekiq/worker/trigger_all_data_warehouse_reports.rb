# frozen_string_literal: true

module Worker
  class TriggerAllDataWarehouseReports
    include Sidekiq::Worker

    def perform
      Helper::Toggles.enabled?("register-api-triggers-reports") do
        ApiFactory.trigger_all_data_warehouse_reports_use_case.execute
      end
    end
  end
end
