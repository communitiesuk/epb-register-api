require 'rake'

class RakeSidekiqError < StandardError
  def initialize(msg="This is a rake exception for sidekiq", exception_type="custom")
    @exception_type = exception_type
    super(msg)
  end
end


module Worker
  class QaWorker
    include Sidekiq::Worker

    def perform
      begin
      get_task("qa_rake").invoke
      rescue StandardError
        raise RakeSidekiqError.new
    end

    def get_task(name)
      rake = ::Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == name }
    end
  end
end
