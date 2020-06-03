# frozen_string_literal: true

require "active_support/core_ext/hash/conversions"

module Domain
  class Lodgement
    attr_reader :raw_data

    def initialize(data, schema_name)
      @data = Hash.from_xml(data).deep_symbolize_keys

      @raw_data = data
      @schema_name = schema_name.to_sym
    end

    def fetch_data(
      data = @data,
      schema = Helper::SchemaListHelper.new(@schema_name).fetch_data_structure
    )
      Helper::DataExtractorHelper.new.fetch_data(data, schema)
    end

      data[:raw_data] = @raw_data

      [data]
    end
  end
end
