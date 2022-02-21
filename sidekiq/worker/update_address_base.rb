module Worker
  class UpdateAddressBase
    include Sidekiq::Worker

    def perform
      Helper::Toggles.enabled?("auto-update-address-base") do
        Dir.chdir("#{__dir__}/../..") do
          system("npm run update-address-base-auto")
        end
      end
    end
  end
end
