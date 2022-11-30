# frozen_string_literal: true

module Worker
  class TriggerDataWarehouseReport
    include Sidekiq::Worker

    def perform(*reports)
      Helper::Toggles.enabled?("register-api-triggers-reports") do
        trigger_report_use_case = ApiFactory.trigger_data_warehouse_report_use_case
        reports.each { |report| trigger_report_use_case.execute report: }
      end
    end
  end
end
