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
    if raw_data.length.zero?
      raise Boundary::NoData, "get assessment count by scheme name and type"

    else
      csv_data = CSV.generate(
        write_headers: true,
        headers: raw_data.first.keys,
      ) { |csv| raw_data.each { |row| csv << row } }
      File.write(csv_file, csv_data)
    end

    # message = "test posting to slack"

    uri = URI(ENV["SLACK_SUPPORT_URL"])
    req = Net::HTTP::Post.new(uri)

    req.set_form(
      [
        [
          "file",
          File.open(csv_file),
        ],
        [
          "initial_comment",
          "Shakes the cat",
        ],
        %w[
          channels
          team-epb-support
        ],
      ],
      "multipart/form-data",
    )

    req_options = {
      use_ssl: uri.scheme == "https",
    }
    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(req)
    end

    File.delete(csv_file)
    # Helper::SlackHelper.post_to_slack text: message, webhook_url: ENV["EPB_TEAM_SLACK_URL"]
  end
end
