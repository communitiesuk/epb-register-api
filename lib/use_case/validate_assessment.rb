module UseCase
  class ValidateAssessment
    class InvalidXmlException < StandardError
    end

    def execute(xml, schema_location)
      validate_xml?(xml, schema_location)
    end

  private

    def validate_xml?(xml, schema)
      xsddoc = Nokogiri.XML(File.read(schema), schema)
      xsd = Nokogiri::XML::Schema.from_document(xsddoc)
      file = Nokogiri.XML(xml) { |config| config.huge.strict }
      errors = xsd.validate(file)

      raise InvalidXmlException, errors.map(&:message).join(", ") if errors.any?

      true
    rescue Nokogiri::XML::SyntaxError => e
      raise InvalidXmlException, e.message
    end
  end
end
