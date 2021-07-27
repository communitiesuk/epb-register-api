module Worker
  class TestRake
    include Sidekiq::Worker


    def perform
      rake = Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == 'test_worker' }.invoke
    rescue StandardError => e
      pp "sidekiq error #{e.message}"
    end
  end
end
