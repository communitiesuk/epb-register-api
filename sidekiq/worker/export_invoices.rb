require_relative "./worker_helpers"

module Worker
  class ExportInvoices
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      @end_date = Date.today.strftime("%Y-%m-01")
      @start_date = Date.yesterday.strftime("%Y-%m-01")
      @monthly_invoice_rake = rake_task("data_export:export_invoices")
      call_rake("scheme_name_type")
    end

  private

    def call_rake(report_type)
      @monthly_invoice_rake.invoke(@start_date, @end_date, report_type)
    rescue Boundary::NoData
      message = ":alert_slow No data for invoice report: #{report_type} - #{Date.parse(@start_date).strftime('%B %Y')}"
      Worker::SlackNotification.perform_async(message)
    rescue Boundary::SlackMessageError
      message = ":alert_slow Unable to post invoice report to slack: #{report_type} - #{Date.parse(@start_date).strftime('%B %Y')}"
      Worker::SlackNotification.perform_async(message)
    end
  end
end
