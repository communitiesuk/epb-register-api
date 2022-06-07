namespace :maintenance do
  desc "Save statistics for a date (defaults to yesterday)"
  task :daily_statistics, %i[date] do |_, args|
    date = args.date

    if date
      parsable = begin
        Date.strptime(date, "%Y-%m-%d")
      rescue StandardError
        false
      end
      raise(ArgumentError) unless parsable
    else
      yesterday = (Time.now.to_date - 1).strftime("%F")
      date = yesterday
    end

    ApiFactory.save_daily_assessments_stats_use_case
      .execute(date:, assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT DEC-RR])

    puts "Statistics for #{date} saved"
  end
end
