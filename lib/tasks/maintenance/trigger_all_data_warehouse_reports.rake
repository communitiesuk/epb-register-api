namespace :maintenance do
  desc "Trigger all reports to be generated within the data warehouse"
  task :trigger_all_data_warehouse_reports do
    ApiFactory.trigger_all_data_warehouse_reports_use_case.execute
  end
end
