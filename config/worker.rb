require 'sidekiq'
require 'sidekiq-cron'
require 'zeitwerk'
# require_relative '../lib/helper/redis_configuration_reader'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/helper")
loader.push_dir("#{__dir__}/../lib/workers")
loader.setup

environment = ENV['STAGE']

# redis_url = Helper::RedisConfigurationReader.read_configuration_url("mhclg-epb-redis-scheduler-#{environment}")
redis_url = "redis://@localhost:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, network_timeout: 5 }
end

schedule_file = "./config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
