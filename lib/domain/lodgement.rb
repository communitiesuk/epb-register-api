# frozen_string_literal: true

module Domain
  class Lodgement
    def initialize(data, schema_name)
      @data = data
      @schema_name = schema_name.to_sym
    end

    def fetch_data(data = @data, schema = Helper::SchemaListHelper.new(@schema_name).fetch_data_structure)
      Helper::DataExtractorHelper.new.fetch_data(data, schema)
    end

    def type
      Helper::SchemaListHelper.new(@schema_name).report_type
    end
  end
end
