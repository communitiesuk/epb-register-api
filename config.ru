require 'sentry-ruby'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib/")
loader.setup

Sentry.init { |config| config.environment = ENV['STAGE'] }
use Sentry::Rack::CaptureExceptions

run RegisterApiService
