# frozen_string_literal: true

ruby "3.1.2"

source "https://rubygems.org"
group :development do
  gem "debase", "~> 0.2", ">= 0.2.5.beta2"
  gem "sinatra-contrib"
end

group :worker do
  gem "http"
  gem "sidekiq", "~> 6.5.4"
  gem "sidekiq-cron", "~> 1.7.0"
end

group :test do
  gem "database_cleaner"
  gem "mock_redis", "~> 0.32.0"
  gem "pry", "~> 0.14.1"
  gem "rack-test", "~> 2.0.2"
  gem "rspec", "~>3.11"
  gem "timecop", "~> 0.9.5"
  gem "webmock", "~> 3.18"
  gem "wisper-rspec", "~> 1.0", ">= 1.0.1"
end

gem "aws-sdk-s3", "~> 1.114"
gem "epb-auth-tools", "~> 1.0.8"
gem "epb_view_models", "~> 1.0", ">= 1.0.19"
gem "geocoder", "~> 1.8.0"
gem "json-schema", "~> 3.0"
gem "namecase", "~> 2.0"
gem "nokogiri", "~> 1.13.8"
gem "ougai", "~> 2.0"
gem "pg", "~> 1.4"
gem "puma", "~> 5.6"
gem "rake", "~> 13.0", ">= 13.0.6"
gem "redis", "~> 4.7.1"
gem "rubocop", "~> 1.35.0"
gem "rubocop-govuk", "~> 4.7"
gem "rubocop-performance", require: false
gem "rubyzip", "~> 2.3.2"
gem "sentry-ruby", "~> 5.4"
gem "sinatra", "~> 2.2"
gem "sinatra-activerecord", "~> 2.0.25"
gem "sinatra-cross_origin", "~> 0.4.0"
gem "unleash", "~> 4.3.0"
gem "wisper", "~> 2.0.1", git: "https://github.com/jstoks/wisper.git", branch: "ruby-3-compat-drop-2-6"
gem "zeitwerk", "~> 2.4.1"
