module Worker
  class TestWorker
    include Sidekiq::Worker

    def perform
      puts "Hello, I am a little worker"
    end
  end
end

