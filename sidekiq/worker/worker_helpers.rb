module Worker
  module Helpers
    def rake_task(name)
      rake = Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == name }
    end
  end
end
