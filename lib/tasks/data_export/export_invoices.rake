require "notifications/client"
require_relative "./export_invoices_helper"

namespace :data_export do
  desc "Export invoices on the 1st of the month every month"

  task :export_invoices, [:start_date, :end_date] do |_, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    get_assessment_count_by_scheme_name_type = ApiFactory.get_assessment_count_by_scheme_name_type

    raw_data =
      get_assessment_count_by_scheme_name_type.execute(
        Date.parse(start_date),
        Date.parse(end_date),
      )

    csv_file = "assessment_count_by_scheme_name_type.csv"

    Helper::ExportInvoicesHelper.save_csv_file(raw_data, csv_file)
    Helper::ExportInvoicesHelper.send_email(csv_file)
    File.delete(csv_file)
  end
end
