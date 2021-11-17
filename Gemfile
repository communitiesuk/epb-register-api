# frozen_string_literal: true

ruby "2.7.3"

source "https://rubygems.org" do
  group :development do
    gem "debase"
    gem "sinatra-contrib"
  end

  group :worker do
    gem "redis", "~> 4.5.1"
    gem "sidekiq", "~> 6.3.1"
    gem "sidekiq-cron", "~> 1.2.0"
  end

  group :test do
    gem "database_cleaner"
    gem "mock_redis", "~> 0.29.0"
    gem "pry", "~> 0.14.1"
    gem "rack-test", "~> 1.1.0"
    gem "rspec", "~>3.10"
    gem "timecop", "~> 0.9.4"
    gem "webmock", "~> 3.14"
    gem "wisper-rspec", "~> 1.0", ">= 1.0.1"
  end

  gem "aws-sdk-s3", "~> 1.105"
  gem "epb-auth-tools", "~> 1.0.8"
  gem "epb_view_models", "~> 1.0", "~> 1.0.14"
  gem "geocoder", "~> 1.7.0"
  gem "json-schema", "~> 2.8"
  gem "namecase", "~> 2.0"
  gem "nokogiri", "~> 1.12.5"
  gem "ougai", "~> 2.0"
  gem "pg", "~> 1.2", ">= 1.2.3"
  gem "puma", "~> 5.5"
  gem "rake", "~> 13.0", ">= 13.0.6"
  gem "rubocop-govuk", "~> 4.1"
  gem "rubocop-performance", require: false
  gem "rubyzip", "~> 2.3.2"
  gem "sentry-ruby", "~> 4.8"
  gem "sinatra", "~> 2.0", ">= 2.0.7"
  gem "sinatra-activerecord", "~> 2.0.23"
  gem "sinatra-cross_origin", "~> 0.4.0"
  gem "unleash", "~> 3.2.4"
  gem "wisper", "~> 2.0", ">= 2.0.1"
  gem "zeitwerk", "~> 2.4.1"
end
