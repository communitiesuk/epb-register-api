module Worker
  class SavePreviousDayStatistics
    include Sidekiq::Worker

    def perform
      rake_task("maintenance:daily_statistics").invoke
    rescue UseCase::SaveDailyAssessmentsStats::NoDataException
      puts "No assessments lodged yesterday to calculate statistics"
    end

  private

    def rake_task(name)
      rake = Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == name }
    end
  end
end
