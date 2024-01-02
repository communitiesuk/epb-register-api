require "sidekiq"
require "sidekiq-cron"
require "zeitwerk"
require "rake"
require "sentry-ruby"

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
  redis_url = ENV["EPB_WORKER_REDIS_URI"]
  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url, network_timeout: 5 }
  end
end

SCHEDULE_FILE = "./sidekiq/schedule.yml".freeze
DEVELOPMENT_SCHEDULE_FILE = "./sidekiq/schedule_dev.yml".freeze

if environment == "development"
  schedule_file = DEVELOPMENT_SCHEDULE_FILE
  unless File.exist? schedule_file
    # generate a development schedule file based on existing schedule but commented out
    File.open(SCHEDULE_FILE, "rb") do |original|
      File.open(DEVELOPMENT_SCHEDULE_FILE, "wb") do |dev_template|
        while (buffer = original.read(4096))
          dev_template << buffer.split("\n").map { |line| "##{line}" }.join("\n")
        end
      end
    end
  end

  puts "\e[33mNB. as Sidekiq is running in a development environment, it is using #{DEVELOPMENT_SCHEDULE_FILE} rather than the production schedule file!\e[0m"
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV["EPB_WORKER_REDIS_URI"] || nil }
  end
else
  schedule_file = SCHEDULE_FILE
end

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_file) || {})
end

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = %i[sentry_logger http_logger]

  # To activate performance monitoring, set one of these options.
  # We recommend adjusting the value in production:
  config.traces_sample_rate = 1.0
end
