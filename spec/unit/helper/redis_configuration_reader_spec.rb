# frozen_string_literal: true

describe Helper::RedisConfigurationReader do
  subject { described_class }

  context "Given VCAP_SERVICES has a redis configuation" do
    let(:instance_name) { "mhclg-epb-redis-scheduler-integration" }

    before do
      vcap_services = <<-JSON
      {
        "redis": [
          {
            "credentials": {
              "uri": "rediss://:my_password@localhost:6379"
            },
            "instance_name": "#{instance_name}"
          }
        ]
      }
      JSON
      stub_const("ENV", { "VCAP_SERVICES" => vcap_services })
    end

    it "returns the redis configuration URL if the instance name exists" do
      redis_config_url = subject.read_configuration_url(instance_name)
      expect(redis_config_url).to eq("rediss://:my_password@localhost:6379")
    end

    it "raises a configuration error" do
      expect { subject.read_configuration_url("missing_name") }.to raise_error(
        Helper::RedisConfigurationReader::ConfigurationError,
        "missing_name is not a valid redis instance",
      )
    end
  end

  context "Given no redis configuration is present in VCAP_SERVICES" do
    before { stub_const("ENV", { "VCAP_SERVICES" => "{}" }) }

    it "raises a configuration error" do
      expect {
        subject.read_configuration_url("my_instance_name")
      }.to raise_error(
        Helper::RedisConfigurationReader::ConfigurationError,
        "No Redis configuration found in VCAP_SERVICES",
      )
    end
  end
end
