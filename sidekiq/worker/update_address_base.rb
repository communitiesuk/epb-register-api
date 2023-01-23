module Worker
  class UpdateAddressBase
    include Sidekiq::Worker

    def perform
      Dir.chdir("#{__dir__}/../..") do
        system("npm run update-address-base-auto")
      end
    end
  end
end
