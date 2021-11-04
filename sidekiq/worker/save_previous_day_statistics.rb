require_relative "./worker_helpers"

module Worker
  class SavePreviousDayStatistics
    include Sidekiq::Worker
    include Worker::Helpers

    def perform
      rake_task("maintenance:daily_statistics").invoke
    rescue Boundary::NoData
      puts "No assessments lodged yesterday to calculate statistics"
    end
  end
end
