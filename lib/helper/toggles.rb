require "unleash"

module Helper
  class Toggles
    def self.enabled?(toggle_name, default: false)
      unless @unleash
        Unleash.configure do |config|
          config.url = ENV["EPB_UNLEASH_URI"]
          config.app_name = "toggles-#{ENV['STAGE']}"
          config.log_level = Logger::ERROR
          config.custom_http_headers = { 'Authorization': ENV["EPB_UNLEASH_AUTH_TOKEN"] } if ENV["EPB_UNLEASH_AUTH_TOKEN"]
        end

        @unleash = Unleash::Client.new
      end

      enabled = @unleash.is_enabled? toggle_name, nil, default
      yield if block_given? && enabled

      enabled
    end

    def self.shutdown!
      @unleash.shutdown! if @unleash
    end
  end
end
