require "sidekiq"
require "sidekiq-cron"
require "zeitwerk"
require "rake"

class SidekiqLoader
  def self.setup
    loader = Zeitwerk::Loader.new
    loader.push_dir("#{__dir__}/../lib")
    loader.push_dir("#{__dir__}/../sidekiq")
    loader.setup
  end
end

SidekiqLoader.setup

environment = ENV["STAGE"] || "development"

unless %w[development test].include? environment
  redis_url = RedisConfigurationReader.read_configuration_url("dluhc-epb-redis-sidekiq-#{environment}")
  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url, network_timeout: 5 }
  end
end

schedule_file = "./sidekiq/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
end

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = %i[sentry_logger http_logger]

  # To activate performance monitoring, set one of these options.
  # We recommend adjusting the value in production:
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |_context|
    0.5
  end
end
