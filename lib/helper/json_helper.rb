module Helper
  class JsonHelper
    def convert_to_ruby_hash(json)
      symbolized_keys_hash = JSON.parse(json)
      symbolized_keys_hash.deep_transform_keys { |k| k.to_s.underscore.to_sym }
    end
  end
end
