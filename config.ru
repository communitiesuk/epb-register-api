require "sentry-ruby"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib/")
loader.setup

Sentry.init do |config|
  config.environment = ENV["STAGE"]
end

run RegisterApiService
