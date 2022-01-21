# frozen_string_literal: true

require "active_support"
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
      data = []

      xml = Nokogiri.XML @raw_data
      xml.remove_namespaces!

      rrns = xml.xpath("//RRN").map(&:text)

      rrns.each do |rrn|
        report =
          ViewModel::Factory
            .new
            .create(@raw_data, @schema_name.to_s, rrn)
            .to_hash
        report[:raw_data] = @raw_data

        data << report
      end

      data
    end
  end
end
