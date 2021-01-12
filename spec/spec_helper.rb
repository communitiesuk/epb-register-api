ENV["RACK_ENV"] = "test"
ENV["STAGE"] = "test"
ENV["EPB_UNLEASH_URI"] = "https://google.com"

require "assertive_client"
require "samples"
require "database_cleaner"
require "epb-auth-tools"
require "nokogiri"
require "rack/test"
require "rake"
require "rspec"
require "sinatra/activerecord"
require "webmock"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/")
loader.push_dir("#{__dir__}/../spec/test_doubles/")
loader.setup

ENV["JWT_ISSUER"] = "test.issuer"
ENV["JWT_SECRET"] = "test.secret"
ENV["SILENT_EVENTS"] = "true"

rake = Rake::Application.new
Rake.application = rake
rake.load_rakefile

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

def add_postcodes(
  postcode,
  latitude = 0,
  longitude = 0,
  region = nil,
  clean = true
)
  db = ActiveRecord::Base

  truncate(postcode) if clean

  db.connection.execute(
    "INSERT INTO postcode_geolocation (postcode, latitude, longitude, region) VALUES('#{
      postcode
    }', #{latitude.to_f}, #{longitude.to_f}, #{
      region.nil? ? 'NULL' : (db.connection.quote region)
    })",
  )
end

def add_outcodes(
  outcode,
  latitude = 0,
  longitude = 0,
  region = nil,
  clean = true
)
  db = ActiveRecord::Base

  truncate(outcode) if clean

  db.connection.execute(
    "INSERT INTO postcode_outcode_geolocations (outcode, latitude, longitude, region) VALUES('#{
      db.sanitize_sql(outcode)
    }', #{latitude.to_f}, #{longitude.to_f}, '#{region}')",
  )
end

def truncate(postcode)
  if postcode == Regexp.new(Helper::RegexHelper::POSTCODE, Regexp::IGNORECASE)
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE postcode_geolocation")
  else
    ActiveRecord::Base.connection.execute(
      "TRUNCATE TABLE postcode_outcode_geolocations",
    )
  end
end

def add_address_base(uprn:)
  ActiveRecord::Base.connection.execute(
    "INSERT INTO address_base (uprn) VALUES(" +
      ActiveRecord::Base.connection.quote(uprn) + ")",
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

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rake::Task["db:seed"].invoke

    fuel_price_mock = GreenDealFuelDataMock.new
    Rake::Task["green_deal_update_fuel_data"].invoke
    fuel_price_mock.disable
  end

  config.before(:each) { DatabaseCleaner.strategy = :transaction }

  config.before(:each) { DatabaseCleaner.start }

  config.after(:each) { DatabaseCleaner.clean }

  config.before(:all) { DatabaseCleaner.start }

  config.after(:all) { DatabaseCleaner.clean }
end
