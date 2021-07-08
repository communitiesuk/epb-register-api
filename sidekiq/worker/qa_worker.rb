require 'rake'

module Worker
  class QaWorker
    include Sidekiq::Worker

    def perform
      get_task("qa_rake").invoke
    end

    def get_task(name)
      rake = ::Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == name }
    end
  end
end
