module Helper
  class ExportInvoicesHelper
    def self.save_csv_file(raw_data, csv_file)
      if raw_data.length.zero?
        raise Boundary::NoData, "get assessment count by scheme name and type"

      else
        csv_data = CSV.generate(
          write_headers: true,
          headers: raw_data.first.keys,
        ) { |csv| raw_data.each { |row| csv << row } }
        File.write(csv_file, csv_data)
      end
    end

    def self.send_email(csv_file)
      notify_client = ApiFactory.notify_client

      File.open(csv_file, "rb") do |f|
        notify_client.send_email(
          email_address: ENV["INVOICE_EMAIL_RECIPIENT"],
          template_id: ENV["INVOICE_TEMPLATE_ID"],
          personalisation: {
            link_to_file: Notifications.prepare_upload(f, true),
          },
        )
      end
    end
  end
end
