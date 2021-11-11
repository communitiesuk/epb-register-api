namespace :maintenance do
  desc "Save statistics for yesterday"
  task :daily_statistics do
    yesterday = (Time.now.to_date - 1).strftime("%F")

    begin
      ApiFactory.save_daily_assessments_stats_use_case
        .execute(date: yesterday, assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT DEC-RR])

      puts "Statistics for #{yesterday} saved"
    rescue Boundary::TerminableError
      raise Boundary::NoData, yesterday
    end
  end
end
