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

def assertive_put(path, body, accepted_responses)
  response = authenticate_and { put(path, body.to_json) }
  check_response(response, accepted_responses)
end

def assertive_get(path, accepted_responses)
  response = authenticate_and { get(path) }
  check_response(response, accepted_responses)
end

def assertive_post(path, body, accepted_responses)
  response = authenticate_and { post(path, body.to_json) }
  check_response(response, accepted_responses)
end

def fetch_assessors(scheme_id, accepted_responses = [200])
  get("/api/schemes/#{scheme_id}/assessors")
end

def fetch_assessor(scheme_id, assessor_id)
  authenticate_and { get("/api/schemes/#{scheme_id}/assessors/#{assessor_id}") }
end

def add_assessor(scheme_id, assessor_id, body, accepted_responses = [200, 201])
  assertive_put(
    "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
    body,
    accepted_responses
  )
end

def add_scheme(name = 'test scheme', accepted_responses = [201])
  JSON.parse(
    assertive_post('/api/schemes', { name: name }, accepted_responses).body
  )[
    'data'
  ][
    'schemeId'
  ]
end

def add_scheme_then_assessor(body, accepted_responses = [200, 201])
  scheme_id = add_scheme
  response = add_assessor(scheme_id, 'TEST_ASSESSOR', body, accepted_responses)
  response
end

def fetch_assessment(assessment_id, accepted_responses = [200])
  assertive_get(
    "api/assessments/domestic-epc/#{assessment_id}",
    accepted_responses
  )
end

def migrate_assessment(
  assessment_id, assessment_body, accepted_responses = [200]
)
  assertive_put(
    "api/assessments/domestic-epc/#{assessment_id}",
    assessment_body,
    accepted_responses
  )
end

def assessments_search_by_postcode(postcode, accepted_responses = [200])
  assertive_get(
    "/api/assessments/domestic-epc/search?postcode=#{postcode}",
    accepted_responses
  )
end

def assessments_search_by_assessment_id(
  assessment_id, accepted_responses = [200]
)
  assertive_get(
    "/api/assessments/domestic-epc/search?assessment_id=#{assessment_id}",
    accepted_responses
  )
end

def assessments_search_by_street_name_and_town(
  street_name, town, accepted_responses = [200]
)
  assertive_get(
    "/api/assessments/domestic-epc/search?street_name=#{street_name}&town=#{
      town
    }",
    accepted_responses
  )
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
