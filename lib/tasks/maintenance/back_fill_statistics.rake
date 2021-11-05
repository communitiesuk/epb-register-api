namespace :maintenance do
  desc "Back fill assessment statistics for a given number of days"
  task :back_fill_statistics, %i[number_days] do |_, args|
    number_days = args.number_days
    days_saved = 0
    gateway = Gateway::AssessmentStatisticsGateway.new

    raise Boundary::ArgumentMissing, "number_days" unless number_days

    last_day = gateway.min_assessment_date

    number_days.to_i.times do |i|
      assessment_date = last_day - (i + 1).days
      begin
        ApiFactory.save_daily_assessments_stats_use_case.execute(date: assessment_date.strftime("%F"), assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT AC-REPORT])
        days_saved += 1
      rescue Boundary::NoData
        pp "back_fill_statistics error - no data saved for #{assessment_date} "
      end
    end

    puts "Statistics for the last #{days_saved} days saved"
  end
end
