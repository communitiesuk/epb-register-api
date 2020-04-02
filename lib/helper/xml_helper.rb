# frozen_string_literal: true

require 'active_support/core_ext/hash/conversions'

module Helper
  class XmlHelper
    def convert_to_hash(xml, schema)
      xsd = Nokogiri::XML.Schema(schema)
      file = Nokogiri.XML(xml)

      Hash.from_xml(file.to_s).deep_symbolize_keys if xsd.validate(file).empty?
    end
  end
end
