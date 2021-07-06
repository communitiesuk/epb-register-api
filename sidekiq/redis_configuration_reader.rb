class RedisConfigurationReader
  class ConfigurationError < StandardError; end

  def self.read_configuration_url(instance_name)
    vcap_services = JSON.parse(ENV["VCAP_SERVICES"], symbolize_names: true)

    if vcap_services[:redis].nil?
      raise ConfigurationError,
            "No Redis configuration found in VCAP_SERVICES"
    end

    vcap_services[:redis].each do |config|
      if config[:instance_name] == instance_name
        return config.dig(:credentials, :uri)
      end
    end

    raise ConfigurationError,
          "#{instance_name} is not a valid redis instance"
  end
end
