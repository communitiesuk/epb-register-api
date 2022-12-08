# frozen_string_literal: true

ruby "3.1.2"

source "https://rubygems.org"
group :development do
  gem "debase", "~> 0.2", ">= 0.2.5.beta2"
  gem "sinatra-contrib"
end

group :worker do
  gem "http"
  gem "sentry-sidekiq", "~> 5.7.0"
  gem "sidekiq", "~> 6.5.6", "< 7"
  gem "sidekiq-cron", "~> 1.9.0"
end

group :test do
  gem "database_cleaner"
  gem "mock_redis", "~> 0.34.0"
  gem "pry", "~> 0.14.1"
  gem "rack-test", "~> 2.0.2"
  gem "rspec", "~>3.12"
  gem "timecop", "~> 0.9.6"
  gem "webmock", "~> 3.18"
  gem "wisper-rspec", "~> 1.0", ">= 1.0.1"
end

gem "archive-zip"
gem "aws-sdk-s3", "~> 1.117"
gem "epb-auth-tools", "~> 1.1.0"
gem "epb_view_models", "~> 1.0"
gem "geocoder", "~> 1.8.0"
gem "json-schema", "~> 3.0"
gem "namecase", "~> 2.0"
gem "nokogiri", "~> 1.13.10"
gem "ougai", "~> 2.0"
gem "pg", "~> 1.4"
gem "puma", "~> 6.0"
gem "rake", "~> 13.0", ">= 13.0.6"
gem "redis", "~> 4.8.0"
gem "rubocop", "~> 1.39.0"
gem "rubocop-govuk", "~> 4.7"
gem "rubocop-performance", require: false
gem "rubyzip", "~> 2.3.2"
gem "sentry-ruby", "~> 5.7"
gem "sinatra", "~> 3.0"
gem "sinatra-activerecord", "~> 2.0.26"
gem "sinatra-cross_origin", "~> 0.4.0"
gem "unleash", "~> 4.4.0"
gem "wisper", "~> 2.0.1", git: "https://github.com/jstoks/wisper.git", branch: "ruby-3-compat-drop-2-6"
gem "zeitwerk", "~> 2.6.6"
