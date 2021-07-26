module Worker
  class TestLib
    include Sidekiq::Worker

    def perform
      begin
        use_case =  UseCase::FetchSchemes.new
        use_case.execute
        pp 'sidekiq can load object and execute code'
        rescue => e
          pp "sidekiq error #{e.message}"
      end
    end
  end
end
