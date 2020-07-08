require "simplecov"
SimpleCov.start

ENV["RACK_ENV"] = "test"
ENV["EPB_UNLEASH_URI"] = "https://google.com"

require "rspec"
require "sinatra/activerecord"
require "rack/test"
require "database_cleaner"
require "zeitwerk"
require "epb-auth-tools"
require "assertive_client"
require "nokogiri"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/")
loader.push_dir("#{__dir__}/../spec/test_doubles/")
loader.setup

ENV["JWT_ISSUER"] = "test.issuer"
ENV["JWT_SECRET"] = "test.secret"
ENV["SILENT_EVENTS"] = "true"

GREEN_DEAL_PLAN_SCHEMA = Controller::GreenDealPlanController::SCHEMA

class UnexpectedApiError < StandardError; end

module RSpecRegisterApiServiceMixin
  include Rack::Test::Methods

  def app
    RegisterApiService
  end
end

def authenticate_and(request = nil, scopes = [], supplementary = {}, &block)
  auth = "Bearer " + get_valid_jwt(scopes, supplementary)

  if request.nil?
    header "Authorization", auth
  else
    request["Authorization"] = auth
  end

  response = block.call

  header "Authorization", nil
  response
end

def authenticate_with_data(data = {}, scopes, &block)
  authenticate_and(nil, scopes, data) { block.call }
end

def get_valid_jwt(scopes = [], sup = {})
  token =
    Auth::Token.new iat: Time.now.to_i,
                    exp: Time.now.to_i + (60 * 60),
                    iss: ENV["JWT_ISSUER"],
                    sub: "test-subject",
                    scopes: scopes,
                    sup: sup

  token.encode ENV["JWT_SECRET"]
end

def opt_out_assessment(assessment_id)
  ActiveRecord::Base.connection.execute(
    "UPDATE assessments SET opt_out = true WHERE assessment_id = '#{
      assessment_id
    }'",
  )
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.order = :random

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
