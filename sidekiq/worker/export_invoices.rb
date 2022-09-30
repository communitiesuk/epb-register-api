require_relative "./worker_helpers"

module Worker
  class ExportInvoices
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      end_date = Date.today.strftime("%Y-%m-01")
      start_date = Date.yesterday.strftime("%Y-%m-01")
      monthly_invoice_rake = rake_task("data_export:export_invoices")
      monthly_invoice_rake.invoke(start_date, end_date, "scheme_name_type")
    end
  end
end
