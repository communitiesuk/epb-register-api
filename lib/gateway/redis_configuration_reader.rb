module Gateway
  class RedisConfigurationReader
    LOCAL_URL = "redis://127.0.0.1:6379".freeze

    def self.configuration_url(instance_name)
      return LOCAL_URL unless config_defined?(instance_name)

      instance_config(instance_name).dig(:credentials, :uri)
    end

    def self.instance_config(instance_name)
      vcap_services[:redis].find do |redis_config|
        redis_config[:instance_name] == instance_name
      end
    end

    def self.config_defined?(instance_name)
      !(ENV["VCAP_SERVICES"].nil? || vcap_services[:redis].nil? || instance_config(instance_name).nil?)
    end

    def self.vcap_services
      JSON.parse(ENV["VCAP_SERVICES"], symbolize_names: true)
    end

    private_class_method :vcap_services, :config_defined?, :instance_config
  end
end
