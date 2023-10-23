require_relative "./export_invoices_helper"

namespace :data_export do
  desc "Export invoices on the 1st of the month every month"

  task :export_invoices, [:start_date, :end_date, :report_type, :scheme_id] do |_, args|
    start_date = args[:start_date] || ENV["start_date"]
    end_date = args[:end_date] || ENV["end_date"]
    report_type = args[:report_type] || ENV["report_type"]
    scheme_id = args[:scheme_id] || ENV["scheme_id"]
    assessment_use_case = case report_type
                          when "scheme_name_type"
                            ApiFactory.get_assessment_count_by_scheme_name_type
                          when "region_type"
                            ApiFactory.get_assessment_count_by_region_type
                          when "rrn_scheme_type"
                            ApiFactory.get_assessment_rrns_by_scheme_type
                          end

    raw_data = if report_type == "rrn_scheme_type"
                 assessment_use_case.execute(
                   Date.parse(start_date),
                   Date.parse(end_date),
                   scheme_id,
                 )
               else
                 assessment_use_case.execute(
                   Date.parse(start_date),
                   Date.parse(end_date),
                 )
               end

    file_name = scheme_id.nil? ? report_type : "#{report_type}_#{scheme_id}"
    csv_file = "#{file_name}_invoice_report.csv"
    zip_file = "#{file_name}_invoice.zip"

    message = "#{ENV['STAGE']} - Invoice report for #{Date.parse(start_date).strftime('%B %Y')} #{report_type}"
    message.concat(" - scheme_id = #{scheme_id}") unless scheme_id.nil?

    Helper::ExportInvoicesHelper.save_file(raw_data, csv_file, file_name)
    Helper::ExportInvoicesHelper.send_to_slack(zip_file, message)
  end
end
