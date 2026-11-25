# frozen_string_literal: true

require "json-schema"

JSON::Validator.use_multi_json = false
JSON::Validator.register_format_validator(
  "email",
  lambda do |value|
    unless value.include?("@")
      raise JSON::Schema::CustomFormatError, "Must be a valid email"
    end
  end,
)
JSON::Validator.register_format_validator(
  "iso-date",
  lambda do |value|
    unless value.match?(/\d{4}-\d{2}-\d{2}/)
      raise JSON::Schema::CustomFormatError, "Must be date in format YYYY-MM-DD"
    end

    Date.strptime(value, "%Y-%m-%d")
  rescue Date::Error
    raise JSON::Schema::CustomFormatError, "Must be date in format YYYY-MM-DD"
  end,
)
JSON::Validator.register_format_validator(
  "telephone",
  lambda do |value|
    if value.size > 256
      raise JSON::Schema::CustomFormatError, "Must be less than 257 chars"
    end
  end,
)

module Helper
  module JsonHelper
    class << self
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
        hash.as_json.deep_transform_keys { it.camelize(:lower) }.to_json
      end

    private

      def extract_failed_properties(schema:, json:)
        JSON::Validator.fully_validate(schema, json).map { it.scan(/'#\/([a-zA-Z]+)'/) }.flatten
      end
    end
  end
end
