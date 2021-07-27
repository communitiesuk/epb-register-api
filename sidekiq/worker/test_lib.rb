module Worker
  class TestLib
    include Sidekiq::Worker

    def perform
      use_case = UseCase::FetchSchemes.new
      pp use_case.execute
    rescue StandardError => e
      pp "sidekiq error #{e.message}"
    end
  end
end
