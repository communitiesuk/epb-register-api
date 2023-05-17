module Worker
  class UpdateAddressBase
    include Sidekiq::Worker

    def perform
      system("npm run update-address-base-auto", exception: true)
    end
  end
end
