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

    def fetch_data
      schema = Helper::SchemaListHelper.new(@schema_name)

      data = []

      if schema.fetch_root
        unless @data.first[1][schema.fetch_root.to_sym].is_a? Array
          @data.first[1][schema.fetch_root.to_sym] = [
            @data.first[1][schema.fetch_root.to_sym],
          ]
        end
        @data.first[1][schema.fetch_root.to_sym].each do |inner_data|
          cad_data =
            Helper::DataExtractorHelper.new.fetch_data(
              { schema.fetch_root.to_sym => inner_data },
              schema.fetch_data_structure,
              "",
            )

          cad_data[:raw_data] = @raw_data

          data.push(cad_data)
        end
      else
        cad_data =
          Helper::DataExtractorHelper.new.fetch_data(
            @data,
            schema.fetch_data_structure,
            "",
          )
        cad_data[:raw_data] = @raw_data

        data.push(cad_data)
      end

      data
    end
  end
end
