# frozen_string_literal: true

require 'active_support/core_ext/hash/conversions'

module Helper
  class InvalidXml < StandardError; end

  class XmlHelper
    def convert_to_hash(xml, schema)
      xsd = Nokogiri::XML.Schema(schema)
      file = Nokogiri.XML(xml)
      errors = xsd.validate(file)

      raise InvalidXml, errors.map(&:message).join(', ') if errors.any?

      Hash.from_xml(file.to_s).deep_symbolize_keys if errors.empty?
    end
  end
end
