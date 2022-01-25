require "active_support"
require "active_support/core_ext"
require "sentry-ruby"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib/")
loader.setup

environment = ENV["STAGE"]

Sentry.init do |config|
  config.environment = environment
  config.capture_exception_frame_locals = true
  config.before_send = lambda do |event, hint|
    if hint[:exception].is_a?(Controller::BaseController::ScheduledDowntimeError)
      nil
    else
      event
    end
  end
end

use Sentry::Rack::CaptureExceptions

run RegisterApiService
