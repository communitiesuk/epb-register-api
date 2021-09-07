require 'sentry-ruby'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib/")
loader.setup

environment = ENV['STAGE']

Sentry.init { |config| config.environment = environment }
use Sentry::Rack::CaptureExceptions

EventBroadcaster.disable!

run RegisterApiService
