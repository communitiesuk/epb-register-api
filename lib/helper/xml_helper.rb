# frozen_string_literal: true

require 'active_support/core_ext/hash/conversions'

module Helper
  class XmlHelper
    def load_xml(xml, schema)
      xsd = Nokogiri::XML::Schema(schema)
      file = Nokogiri::XML(xml)

      if xsd.validate(file).empty?
        Hash.from_xml(file.to_s).deep_symbolize_keys
      end
    end
  end
end
