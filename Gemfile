# frozen_string_literal: true

ruby "2.7.3"

source "https://rubygems.org" do
  group :development do
    gem "debase"
    gem "sinatra-contrib"
  end

  group :worker do
    gem "redis", "~> 4.3.1"
    gem "sidekiq", "~> 6.2.1"
    gem "sidekiq-cron", "~> 1.2.0"
  end

  group :test do
    gem "database_cleaner"
    gem "pry", "~> 0.14.1"
    gem "rack-test", "~> 1.1.0"
    gem "rspec", "~>3.10"
    gem "timecop", "~> 0.9.4"
    gem "webmock", "~> 3.13"
  end

  gem "aws-sdk-s3", "~> 1.96"
  gem "epb-auth-tools", "~> 1.0.8"
  gem "epb_view_models", "~> 1.0.2"
  gem "geocoder", "~> 1.6.6"
  gem "json-schema", "~> 2.8"
  gem "nokogiri", "~> 1.12.0"
  gem "ougai", "~> 2.0"
  gem "pg"
  gem "rake"
  gem "rubocop-govuk", "~> 3.17"
  gem "rubocop-performance", require: false
  gem "rubyzip", "~> 2.3.2"
  gem "sentry-ruby", "~> 4.6"
  gem "sinatra", "~> 2.0", ">= 2.0.7"
  gem "sinatra-activerecord", "~> 2.0.23"
  gem "sinatra-cross_origin", "~> 0.4.0"
  gem "unleash", "~> 3.2.2"
  gem "zeitwerk", "~> 2.4.1"
end
