require_relative "./worker_helpers"

module Worker
  class SavePreviousDayStatistics
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      rake_task("maintenance:daily_statistics").invoke
    rescue UseCase::SaveDailyAssessmentsStats::NoDataException
      puts "No assessments lodged yesterday to calculate statistics"
    end
  end
end
