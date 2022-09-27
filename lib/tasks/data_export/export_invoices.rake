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

    if raw_data.length.zero?
      raise Boundary::NoData, "get assessment count by scheme name and type"

    else
      CSV.generate(
        write_headers: true,
        headers: raw_data.first.keys,
      ) { |csv| raw_data.each { |row| csv << row } }
    end

    message = "test posting to slack"
    Helper::SlackHelper.post_to_slack text: message, webhook_url: ENV["EPB_TEAM_SLACK_URL"]
  end
end
