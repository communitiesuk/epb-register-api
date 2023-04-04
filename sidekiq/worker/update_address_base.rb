module Worker
  class UpdateAddressBase
    include Sidekiq::Worker

    def perform
      system("npm run update-address-base-auto")
    end
  end
end
