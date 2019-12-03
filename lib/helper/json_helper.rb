module Helper
  class JsonHelper
    def convert_to_ruby_hash(json)
      JSON.parse(json).deep_transform_keys { |k| k.to_s.underscore.to_sym }
    end

    def convert_to_json(hash)
      JSON.parse(hash.to_json).deep_transform_keys { |k| k.camelize(:lower) }
    end
  end
end
