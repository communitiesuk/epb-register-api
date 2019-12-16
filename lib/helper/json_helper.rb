require 'json-schema'

module Helper
  class JsonHelper
    DATE_FORMAT_PROC = lambda do |value|
      unless begin
               Date.strptime(value, '%Y-%m-%d')
             rescue StandardError
               false
             end
        raise JSON::Schema::CustomFormatError.new(
                'Must be date in format YYYY-MM-DD'
              )
      end
    end

    EMAIL_FORMAT_PROC = lambda do |value|
      raise JSON::Schema::CustomFormatError unless value.include?('@')
    end

    TELEPHONE_FORMAT_PROC = lambda do |value|
      raise JSON::Schema::CustomFormatError if value.size > 256
    end

    def initialize
      JSON::Validator.register_format_validator('email', EMAIL_FORMAT_PROC)
      JSON::Validator.register_format_validator('iso-date', DATE_FORMAT_PROC)
      JSON::Validator.register_format_validator(
        'telephone',
        TELEPHONE_FORMAT_PROC
      )
    end

    def convert_to_ruby_hash(json_string, schema = false)
      json = JSON.parse(json_string)

      JSON::Validator.validate!(schema, json) if schema

      json.deep_transform_keys { |k| k.to_s.underscore.to_sym }
    end

    def convert_to_json(hash)
      JSON.parse(hash.to_json).deep_transform_keys do |k|
        k.camelize(:lower)
      end.to_json
    end
  end
end
