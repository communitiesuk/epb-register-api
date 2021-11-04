namespace :maintenance do
  desc "Back fill assessment statistics for a given number of days"
  task :back_fill_statistics, %i[number_days] do |_, args|
    number_days = args.number_days

    gateway = Gateway::AssessmentStatisticsGateway.new

    raise Boundary::ArgumentMissing, "number_days" unless number_days

    last_day = gateway.min_assessment_date

    number_days.times.each do |i|
      yesterday = (last_day - i).strftime("%F")
      begin
        ApiFactory.save_daily_assessments_stats_use_case
                  .execute(date: yesterday, assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT AC-REPORT])

        puts "Statistics for #{yesterday} saved"
      rescue UseCase::SaveDailyAssessmentsStats::NoDataException
        raise UseCase::SaveDailyAssessmentsStats::NoDataException, "No data to be saved"
      end
    end
  end
end
