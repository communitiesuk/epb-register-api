ENV["RACK_ENV"] = "test"
ENV["STAGE"] = "test"
ENV["EPB_UNLEASH_URI"] = "https://test-toggle-server/api"

require "assertive_client"
require "samples"
require "database_cleaner"
require "epb-auth-tools"
require "nokogiri"
require "rack/test"
require "rake"
require "rspec"
require "sinatra/activerecord"
require "timecop"
require "webmock"
require "zeitwerk"
require "webmock/rspec"

class TestLoader
  def self.setup
    @loader = Zeitwerk::Loader.new
    @loader.push_dir("#{__dir__}/../lib/")
    @loader.push_dir("#{__dir__}/../spec/test_doubles/")
    @loader.setup
  end

  def self.override(path)
    load path
  end
end

TestLoader.setup

def loader_enable_override(name)
  TestLoader.override "overrides/#{name}.rb"
end

def loader_enable_original(lib_name)
  TestLoader.override "#{__dir__}/../lib/#{lib_name}.rb"
end

loader_enable_override "helper/toggles"

ENV["JWT_ISSUER"] = "test.issuer"
ENV["JWT_SECRET"] = "test.secret"
ENV["SILENT_EVENTS"] = "true"

rake = Rake::Application.new
Rake.application = rake
rake.load_rakefile

GREEN_DEAL_PLAN_SCHEMA = Controller::GreenDealPlanController::SCHEMA

class UnexpectedApiError < StandardError
end

module RSpecRegisterApiServiceMixin
  include Rack::Test::Methods

  def app
    RegisterApiService
  end
end

def authenticate_and(request = nil, scopes = [], supplementary = {})
  auth = "Bearer " + get_valid_jwt(scopes, supplementary)

  if request.nil?
    header "Authorization", auth
  else
    request["Authorization"] = auth
  end

  response = yield

  header "Authorization", nil
  response
end

def authenticate_with_data(data = {}, scopes)
  authenticate_and(nil, scopes, data) { yield }
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
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE postcode_geolocation",
    )
  else
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE postcode_outcode_geolocations",
    )
  end
end

def add_uprns_to_address_base(*uprns)
  uprns.each { |uprn| add_address_base(uprn: uprn) }
end

def add_address_base(uprn:)
  count = ActiveRecord::Base.connection.exec_query(
    "SELECT COUNT(*) AS address_count FROM address_base WHERE uprn=%s" % ActiveRecord::Base.connection.quote(uprn.to_s),
  )[0]["address_count"].to_i
  return if count > 0

  ActiveRecord::Base.connection.exec_query(
    "INSERT INTO address_base (uprn) VALUES(" +
      ActiveRecord::Base.connection.quote(uprn) + ")",
  )
end

def remove_from_address_base(uprn:)
  ActiveRecord::Base.connection.exec_query(
    "DELETE FROM address_base WHERE uprn=%s" %
      ActiveRecord::Base.connection.quote(uprn),
  )
end

def get_task(name)
  rake = Rake::Application.new
  Rake.application = rake
  rake.load_rakefile
  rake.tasks.find { |task| task.to_s == name }
end

def date_today
  DateTime.now.strftime("%F")
end

def datetime_today
  DateTime.now.strftime("%F %H:%M:%S")
end

def get_vcap_services
  '{
    "aws-s3-bucket": [
      {
        "binding_name": null,
        "credentials": {
          "aws_access_key_id": "myaccesskey",
          "aws_region": "eu-west-2",
          "aws_secret_access_key": "mysecret",
          "bucket_name": "mybucket",
          "deploy_env": ""
        },
        "instance_name": "myinstance",
        "label": "aws-s3-bucket",
        "name": "myinstance",
        "plan": "default",
        "provider": null,
        "syslog_drain_url": null,
        "tags": [
          "s3"
        ],
        "volume_mounts": []
      }
    ]
  }'
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

  config.before(:all, set_with_timecop: true) { Timecop.freeze(2021, 6, 21) }

  config.after(:all, set_with_timecop: true) { Timecop.return }

  config.before { DatabaseCleaner.strategy = :transaction }

  config.before { DatabaseCleaner.start }

  config.after { DatabaseCleaner.clean }

  config.before(:all) { DatabaseCleaner.start }

  config.after(:all) { DatabaseCleaner.clean }
end
