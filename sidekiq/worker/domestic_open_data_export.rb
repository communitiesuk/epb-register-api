require_relative "./worker_helpers"

module Worker
  class DomesticOpenDataExport
    include Sidekiq::Worker
    include Worker::Helpers

    attr_reader :start_date, :end_date

    def perform
      ENV["INSTANCE_NAME"] = "mhclg-epb-s3-open-data-export"
      @end_date = Date.today.strftime("%Y-09-01")
      @start_date = Date.yesterday.strftime("%Y-%m-01")
      @monthly_rake = rake_task("open_data:export_assessments")
      puts "<<< posting ODE to S3"
      @monthly_rake.invoke("not_for_odc", "SAP-RDSAP", @start_date, @end_date)
    rescue Boundary::OpenDataEmpty
      message = ":alert_slow No data for domestic ODC Export"
      Worker::SlackNotification.perform_async(message)
    end
  end
end
