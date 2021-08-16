module Helper
  class Toggles
    def self.enabled?(toggle_name, default: false)
      @toggles_enabled_features ||= {}

      matching = @toggles_enabled_features[toggle_name]

      return matching if matching

      default
    end

    def self.set_feature(toggle_name, value)
      @toggles_enabled_features ||= {}

      @toggles_enabled_features[toggle_name] = value

      @toggles_enabled_features[toggle_name]
    end
  end
end
