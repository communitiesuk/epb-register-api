require "unleash"

class Toggles
  def initialize
    unless ENV["STAGE"] == "test"
      Unleash.configure do |config|
        config.url = ENV["EPB_UNLEASH_URI"]
        config.app_name = "toggles-" + ENV["STAGE"]

        @unleash = Unleash::Client.new
      end
    end
  end

  def state(toggle_name)
    ENV["STAGE"] == "test" ? true : @unleash.is_enabled?(toggle_name)
  end
end
