ENV["RACK_ENV"] = "test"
ENV["STAGE"] = "test"
ENV["EPB_UNLEASH_URI"] = "https://test-toggle-server/api"
ENV["EPB_TEAM_SLACK_URL"] = nil # ensure tests don't send Slack notifications

require "assertive_client"
require "samples"
require "database_cleaner"
require "mock_redis"
require "nokogiri"
require "rack/test"
require "rake"
require "rspec"
require "sinatra/activerecord"
require "timecop"
require "webmock"
require "wisper/rspec/matchers"
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
ENV["VALID_DOMESTIC_SCHEMAS"] = "SAP-Schema-19.1.0,SAP-Schema-19.0.0,SAP-Schema-18.0.0,SAP-Schema-NI-18.0.0,RdSAP-Schema-20.0.0,RdSAP-Schema-NI-20.0.0"
ENV["VALID_NON_DOMESTIC_SCHEMAS"] = "CEPC-8.0.0,CEPC-NI-8.0.0"

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

def authenticate_and(request: nil, scopes: [], supplementary: {})
  auth = "Bearer #{get_valid_jwt(scopes, supplementary)}"

  if request.nil?
    header "Authorization", auth
  else
    request["Authorization"] = auth
  end

  response = yield

  header "Authorization", nil
  response
end

def authenticate_with_data(data: {}, scopes: [], &block)
  authenticate_and(scopes:, supplementary: data, &block)
end

def get_valid_jwt(scopes = [], sup = {})
  token =
    Auth::Token.new(iat: Time.now.to_i,
                    exp: Time.now.to_i + (60 * 60),
                    iss: ENV["JWT_ISSUER"],
                    sub: "test-subject",
                    scopes:,
                    sup:)

  token.encode ENV["JWT_SECRET"]
end

def add_postcodes(
  postcode,
  latitude = 0,
  longitude = 0,
  region = nil,
  clean: true
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
  clean: true
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
  uprns.each { |uprn| add_address_base(uprn:) }
end

def add_countries
  ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE countries RESTART IDENTITY CASCADE", "SQL")

  insert_sql = <<-SQL
            INSERT INTO countries(country_code, country_name, address_base_country_code)
            VALUES ('ENG', 'England' ,'["E"]'::jsonb),
                   ('EAW', 'England and Wales', '["E", "W"]'::jsonb),
                     ('UKN', 'Unknown', '{}'::jsonb),
                    ('NIR', 'Northern Ireland', '["N"]'::jsonb),
                    ('SCT', 'Scotland', '["S"]'::jsonb),
            ('', 'Channel Islands', '["L"]'::jsonb),
                ('NR', 'Not Recorded', null)

  SQL
  ActiveRecord::Base.connection.exec_query(insert_sql, "SQL")
end

def add_address_base(uprn:, postcode: nil, country_code: nil)
  ActiveRecord::Base.connection.exec_query(
    "INSERT INTO address_base (uprn, postcode, country_code) VALUES($1, $2, $3) ON CONFLICT DO NOTHING",
    "sql",
    [
      ActiveRecord::Relation::QueryAttribute.new("uprn", uprn, ActiveRecord::Type::String.new),
      ActiveRecord::Relation::QueryAttribute.new("postcode", postcode, ActiveRecord::Type::String.new),
      ActiveRecord::Relation::QueryAttribute.new("country_code", country_code, ActiveRecord::Type::String.new),
    ],
  )
end

def insert_into_address_base(rrn, post_code, address1, address2, town, country_code)
  sql = "INSERT INTO address_base (uprn,
            postcode,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            classification_code,
            address_type,
            country_code)
            VALUES ($1, $2, $3, $4, '', '', $5, 'D', 'Delivery Point', $6)"

  binds = [
    ActiveRecord::Relation::QueryAttribute.new(
      "uprn",
      rrn.to_i.to_s,
      ActiveRecord::Type::String.new,
    ),
    ActiveRecord::Relation::QueryAttribute.new(
      "postcode",
      post_code,
      ActiveRecord::Type::String.new,
    ),
    ActiveRecord::Relation::QueryAttribute.new(
      "address1",
      address1,
      ActiveRecord::Type::String.new,
    ),
    ActiveRecord::Relation::QueryAttribute.new(
      "address2",
      address2,
      ActiveRecord::Type::String.new,
    ),
    ActiveRecord::Relation::QueryAttribute.new(
      "town",
      town,
      ActiveRecord::Type::String.new,
    ),
    ActiveRecord::Relation::QueryAttribute.new(
      "country_code",
      country_code,
      ActiveRecord::Type::String.new,
    ),
  ]

  ActiveRecord::Base.connection.exec_query sql, "SQL", binds
end

def map_lookups_to_country_codes
  gateway = instance_double Gateway::AddressBaseCountryGateway
  allow(gateway).to receive(:lookup_from_postcode) { |postcode| Domain::CountryLookup.new(country_codes: yield(postcode:)) }
  allow(gateway).to receive(:lookup_from_uprn) { |uprn| Domain::CountryLookup.new(country_codes: yield(uprn:)) }
  allow(Gateway::AddressBaseCountryGateway).to receive(:new).and_return(gateway)
end

def get_task(name)
  rake = Rake::Application.new
  Rake.application = rake
  rake.load_rakefile
  rake.tasks.find { |task| task.to_s == name }
end

def date_today
  Time.now.strftime("%F")
end

def date_a_year_ago
  (Time.now - 31_536_000).strftime("%F")
end

def datetime_today
  Time.now.strftime("%F %H:%M:%S")
end

def add_assessment_country_ids
  Gateway::AssessmentsGateway::Assessment.all.each do |item|
    item[:postcode] = item[:postcode].to_s
    country_id = item[:postcode].start_with?("BT") ? 4 : 1
    Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.create(assessment_id: item[:assessment_id], country_id:)
  end
end

def load_green_deal_data
  fuel_price_mock = GreenDealFuelDataMock.new
  gateway = Gateway::GreenDealFuelPriceGateway.new
  response_data = fuel_price_mock.response_data
  gateway.bulk_insert(fuel_price_mock.scan(response_data))
end

ActiveRecord::Base.connects_to(database: { writing: :primary, reading: :primary })

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.include Rack::Test::Methods
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include Wisper::RSpec::BroadcastMatcher

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rake::Task["db:seed"].invoke

    Events::Broadcaster.disable!

    Gateway::DataWarehouseRedisHelper.redis_client_class = MockRedis
  end

  config.before(:all, :set_with_timecop) { Timecop.freeze(Time.utc(2021, 6, 21)) }

  config.after(:all, :set_with_timecop) { Timecop.return }

  config.before { DatabaseCleaner.strategy = :transaction }

  config.before { DatabaseCleaner.start }

  config.before { ApiFactory.clear! }

  config.after { ApiFactory.clear! }

  config.after { DatabaseCleaner.clean }

  config.before(:all) { DatabaseCleaner.start }

  config.after(:all) { DatabaseCleaner.clean }
end

RSpec::Matchers.define(:json_contains_hash) do |kwargs|
  match do |response|
    begin
      json_hash = JSON.parse(response, symbolize_names: true)
    rescue JSON::ParserError
      return false
    end
    return false unless json_hash.respond_to?(:to_a)

    (kwargs.to_a - json_hash.to_a).empty?
  end
end
