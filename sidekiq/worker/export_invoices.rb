require_relative "./worker_helpers"

module Worker
  class ExportInvoices
    include Sidekiq::Worker
    include Worker::Helpers

    sidekiq_options retry: 1

    def perform
      last_month = Time.now - 1.month
      @start_date = last_month.to_date.beginning_of_month.strftime("%Y-%m-%d")
      @end_date = (last_month.to_date.end_of_month + 1.day).strftime("%Y-%m-%d")
      @monthly_invoice_rake = rake_task("data_export:export_invoices")
      call_rake("scheme_name_type")
      call_rake("region_type")
      active_scheme_ids = ApiFactory.fetch_active_schemes_use_case.execute
      active_scheme_ids.each do |i|
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
