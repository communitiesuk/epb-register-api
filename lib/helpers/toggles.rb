require 'unleash'

class Toggles
  def initialize
    Unleash.configure do |config|
      config.url          = ENV['UNLEASH_URI']
      config.app_name     = 'epb-fund-assessor'
      config.backup_file = 'tmp/unleash.json'

      @unleash = Unleash::Client.new
    end
  end

  def state(toggle_name)
    @unleash.is_enabled?(toggle_name)
  end
end