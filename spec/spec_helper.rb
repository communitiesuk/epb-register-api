ENV['RACK_ENV'] = 'development'

require 'rspec'
require 'sinatra/activerecord'
require 'rack/test'
require 'database_cleaner'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/")
loader.setup

module RSpecMixin
  def app
    described_class
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  config.before(:each) { DatabaseCleaner.strategy = :transaction }

  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }

  config.before(:each) { DatabaseCleaner.start }

  config.after(:each) { DatabaseCleaner.clean }

  config.before(:all) { DatabaseCleaner.start }

  config.after(:all) { DatabaseCleaner.clean }
end
