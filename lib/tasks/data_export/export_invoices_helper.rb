require "archive/zip"

module Helper
  class ExportInvoicesHelper
    def self.save_file(raw_data, csv_file)
      if raw_data.length.zero?
        raise Boundary::NoData, "get assessment count by scheme name and type"

      else
        csv_data = CSV.generate(
          write_headers: true,
          headers: raw_data.first.keys,
        ) { |csv| raw_data.each { |row| csv << row } }
        File.write(csv_file, csv_data)

        Archive::Zip.archive("invoice.zip", csv_file)
      end
    end

    def self.send_to_slack(zip_file, _report_type)
      uri = URI("https://slack.com/api/files.upload")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{ENV['SLACK_EPB_BOT_TOKEN']}"
      form = [
        [
          "file",
          File.open(zip_file),
        ],
        [
          "initial comment",
          "report",
        ],
        %w[
          channels
          team-epb-support
        ],
      ]
      req.set_form(
        form,
        "multipart/form-data",
      )

      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end
      if !response.body.empty? && (!response.is_a?(Net::HTTPSuccess) || JSON.parse(response.body)["ok"] == false)
        raise Boundary::SlackMessageError, "Slack error: #{response.body}"
      end
    end
  end
end
