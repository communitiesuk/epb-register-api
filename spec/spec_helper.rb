require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
ENV['EPB_UNLEASH_URI'] = 'https://google.com'

require 'rspec'
require 'sinatra/activerecord'
require 'rack/test'
require 'database_cleaner'
require 'zeitwerk'
require 'epb-auth-tools'
require 'assertive_client'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/")
loader.push_dir("#{__dir__}/../spec/test_doubles/")
loader.setup

ENV['JWT_ISSUER'] = 'test.issuer'
ENV['JWT_SECRET'] = 'test.secret'

class UnexpectedApiError < Exception; end

module RSpecMixin
  def app
    described_class
  end
end

module RSpecAssessorServiceMixin
  include Rack::Test::Methods

  def app
    AssessorService
  end
end

def authenticate_and(request = nil, scopes = [], supplementary = {}, &block)
  auth = 'Bearer ' + get_valid_jwt(scopes, supplementary)

  if request.nil?
    header 'Authorization', auth
  else
    request['Authorization'] = auth
  end

  response = block.call

  header 'Authorization', nil
  response
end

def check_response(response, accepted_responses)
  if accepted_responses.include?(response.status)
    response
  else
    raise UnexpectedApiError.new(
            {
              expected_status: accepted_responses,
              actual_status: response.status,
              response_body: response.body
            }
          )
  end
end


def get_valid_jwt(scopes = [], sup = {})
  token =
    Auth::Token.new iat: Time.now.to_i,
                    iss: ENV['JWT_ISSUER'],
                    sub: 'test-subject',
                    scopes: scopes,
                    sup: sup

  token.encode ENV['JWT_SECRET']
end

RSpec.configure do |config|
  config.include RSpecMixin
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
