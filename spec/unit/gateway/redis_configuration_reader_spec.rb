describe Gateway::RedisConfigurationReader do
  before { allow(ENV).to receive(:[]).and_return(nil) }

  describe ".configuration_url" do
    it "returns redis url" do
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(
        '{
          "redis": [
            {
              "credentials": {
                "uri": "redis://123.0.0.1"
              },
              "instance_name": "test-instance",
              "label": "redis"
            }
          ]
        }',
      )

      expect(described_class.configuration_url("test-instance")).to eq("redis://123.0.0.1")
    end

    it "returns the local redis url when VCAP_SERVICES is not defined" do
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(nil)

      expect(described_class.configuration_url("test-instance")).to eq(Gateway::RedisConfigurationReader::LOCAL_URL)
    end

    it "returns the local redis url when redis config is not defined" do
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(get_vcap_services_stub)

      expect(described_class.configuration_url("test-instance")).to eq(Gateway::RedisConfigurationReader::LOCAL_URL)
    end

    it "returns the local redis url when there is no redis config for the instance" do
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(
        '{
          "redis": [
            {
              "credentials": {
                "uri": "redis://987.0.0.1"
              },
              "instance_name": "some-other-instance"
            }
          ]
        }',
      )

      expect(described_class.configuration_url("test-instance")).to eq(Gateway::RedisConfigurationReader::LOCAL_URL)
    end
  end
end
