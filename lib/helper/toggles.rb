require "unleash"

module Helper
  class Toggles
    def self.enabled?(toggle_name, default = false)
      unless @unleash
        Unleash.configure do |config|
          config.url = ENV["EPB_UNLEASH_URI"]
          config.app_name = "toggles-" + ENV["STAGE"]
        end

        @unleash = Unleash::Client.new
      end

      @unleash.is_enabled? toggle_name, nil, default
    end

    def self.shutdown!
      @unleash.shutdown! if @unleash
    end
  end
end
