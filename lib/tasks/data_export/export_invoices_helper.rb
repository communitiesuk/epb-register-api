require "archive/zip"
require "slack"

module Helper
  class ExportInvoicesHelper
    def self.save_file(raw_data, csv_file, file_name)
      if raw_data.empty?
        raise Boundary::NoData, "get assessment count by scheme name and type #{file_name}"

      else
        csv_data = CSV.generate(
          write_headers: true,
          headers: raw_data.first.keys,
        ) { |csv| raw_data.each { |row| csv << row } }
        File.write(csv_file, csv_data)

        Archive::Zip.archive("#{file_name}_invoice.zip", csv_file)
        File.delete(csv_file)
      end
    end
  end
end
