require_relative "./export_invoices_helper"

namespace :data_export do
  desc "Export invoices on the 1st of the month every month"

  task :export_invoices, [:start_date, :end_date, :report_type, :scheme_id] do |_, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    assessment_use_case = case args[:report_type]
                          when "scheme_name_type"
                            ApiFactory.get_assessment_count_by_scheme_name_type
                          when "region_type"
                            ApiFactory.get_assessment_count_by_region_type
                          when "rrn_scheme_type"
                            ApiFactory.get_assessment_rrns_by_scheme_type
                          end

    raw_data = if args[:report_type] == "rrn_scheme_type"

                 assessment_use_case.execute(
                   Date.parse(start_date),
                   Date.parse(end_date),
                   args[:scheme_id],
                 )
               else
                 assessment_use_case.execute(
                   Date.parse(start_date),
                   Date.parse(end_date),
                 )
               end

    csv_file = "invoice_report.csv"
    zip_file = "invoice.zip"

    Helper::ExportInvoicesHelper.save_file(raw_data, csv_file)
    Helper::ExportInvoicesHelper.send_to_slack(zip_file, args[:report_type])
    File.delete(csv_file)
    File.delete(zip_file)
  end
end
