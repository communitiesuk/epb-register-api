require 'unleash'

Unleash.configure do |config|
  config.url          = ENV['UNLEASH_URI']
  config.app_name     = 'epb-fund-assessor'
  config.backup_file = 'tmp/unleash.json'
end

$unleash = Unleash::Client.new