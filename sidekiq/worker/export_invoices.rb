require_relative "./worker_helpers"

module Worker
  class ExportInvoices
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      # @end_date = Date.today.strftime("%Y-%m-01")
      # @start_date = Date.yesterday.strftime("%Y-%m-01")
      @end_date = "2022-09-01"
      @start_date = "2022-08-01"
      @monthly_invoice_rake = rake_task("data_export:export_invoices")
      call_rake("scheme_name_type")
      call_rake("region_type")
      (1..6).each do |i|
        call_rake("rrn_scheme_type", i)
      end
    end

  private

    def call_rake(report_type, scheme_id = nil)
      scheme_id.nil? ? @monthly_invoice_rake.invoke(@start_date, @end_date, report_type) : @monthly_invoice_rake.invoke(@start_date, @end_date, report_type, scheme_id)
      @monthly_invoice_rake.reenable
    rescue Boundary::NoData => e
      Sentry.capture_exception(e)  if defined?(Sentry)
    rescue Boundary::SlackMessageError => e
      Sentry.capture_exception(e)  if defined?(Sentry)
    end
  end
end
