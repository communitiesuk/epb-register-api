require_relative "./worker_helpers"

module Worker
  class ExportInvoices
    include Sidekiq::Worker
    include Worker::Helpers

    sidekiq_options retry: 1

    def perform
      @end_date = Time.now.strftime("%Y-%m-01")
      @start_date = (Time.parse(@end_date) - 1).strftime("%Y-%m-01")
      @monthly_invoice_rake = rake_task("data_export:export_invoices")
      call_rake("scheme_name_type")
      call_rake("region_type")
      active_scheme_ids = ApiFactory.fetch_active_schemes_use_case.execute
      puts "Active Schemes: #{active_scheme_ids.join(', ')}"
      active_scheme_ids.each do |i|
        call_rake("rrn_scheme_type", i)
      rescue Boundary::NoData => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      rescue Boundary::SlackMessageError => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end
    end

  private

    def call_rake(report_type, scheme_id = nil)
      scheme_id.nil? ? @monthly_invoice_rake.invoke(@start_date, @end_date, report_type) : @monthly_invoice_rake.invoke(@start_date, @end_date, report_type, scheme_id)
    rescue Boundary::NoData => e
      if scheme_id.nil?
        Sentry.capture_exception(e) if defined?(Sentry)
      else
        raise Boundary::NoData, e
      end
    rescue Boundary::SlackMessageError => e
      if scheme_id.nil?
        Sentry.capture_exception(e) if defined?(Sentry)
      else
        raise Boundary::SlackMessageError, e
      end
    ensure
      @monthly_invoice_rake.reenable
    end
  end
end
