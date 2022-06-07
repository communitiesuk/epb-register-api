require "json-schema"

module Helper
  class JsonHelper
    DATE_FORMAT_PROC =
      lambda do |value|
        Date.strptime(value, "%Y-%m-%d")
      rescue StandardError
        raise JSON::Schema::CustomFormatError,
              "Must be date in format YYYY-MM-DD"
      end

    EMAIL_FORMAT_PROC =
      lambda do |value|
        unless value.include?("@")
          raise JSON::Schema::CustomFormatError, "Must be a valid email"
        end
      end

    TELEPHONE_FORMAT_PROC =
      lambda do |value|
        if value.size > 256
          raise JSON::Schema::CustomFormatError, "Must be less than 257 chars"
        end
      end

    POSITIVE_INT_FORMAT_PROC =
      lambda do |value|
        if value.negative?
          raise JSON::Schema::CustomFormatError, "Must be a positive number"
        end
      end

    def initialize
      JSON::Validator.register_format_validator("email", EMAIL_FORMAT_PROC)
      JSON::Validator.register_format_validator("iso-date", DATE_FORMAT_PROC)
      JSON::Validator.register_format_validator(
        "positive-int",
        POSITIVE_INT_FORMAT_PROC,
      )
      JSON::Validator.register_format_validator(
        "telephone",
        TELEPHONE_FORMAT_PROC,
      )
    end

    def convert_to_ruby_hash(json_string, schema: false)
      begin
        json = JSON.parse(json_string)
      rescue JSON::ParserError => e
        raise Boundary::Json::ParseError, e.message
      end

      begin
        JSON::Validator.validate!(schema, json) if schema
      rescue JSON::Schema::ValidationError => e
        raise Boundary::Json::ValidationError.new(e.message, failed_properties: extract_failed_properties(schema:, json:))
      end

      json.deep_transform_keys { |k| k.to_s.underscore.to_sym }
    end

    def convert_to_json(hash)
      JSON.parse(hash.to_json).deep_transform_keys { |k|
        k.camelize(:lower)
      }.to_json
    end

    def extract_failed_properties(schema:, json:)
      JSON::Validator.fully_validate(schema, json).map { |message|
        message.scan(/'#\/([a-zA-Z]+)'/)
      }.flatten
    rescue StandardError
      []
    end
  end
end
