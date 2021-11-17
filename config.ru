require "sentry-ruby"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib/")
loader.setup

environment = ENV["STAGE"]

Sentry.init do |config|
  config.environment = environment
  config.capture_exception_frame_locals = true
end

use Sentry::Rack::CaptureExceptions

run RegisterApiService
