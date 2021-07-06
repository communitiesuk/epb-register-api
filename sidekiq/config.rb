require "sidekiq"
require "sidekiq-cron"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib")
loader.push_dir("#{__dir__}/../sidekiq")
loader.setup

environment = ENV["STAGE"]

redis_url = RedisConfigurationReader.read_configuration_url("mhclg-epb-redis-scheduler-#{environment}")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, network_timeout: 5 }
end

schedule_file = "./sidekiq/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
