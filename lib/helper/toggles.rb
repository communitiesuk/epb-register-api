require 'unleash'

class Toggles
  def initialize
    Unleash.configure do |config|
      config.url = ENV['UNLEASH_URI']
      config.app_name = 'toggles-' + ENV['STAGE']

      @unleash = Unleash::Client.new
    end
  end

  def state(toggle_name)
    @unleash.is_enabled?(toggle_name)
  end
end
