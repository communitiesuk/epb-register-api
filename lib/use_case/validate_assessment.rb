module UseCase
  class ValidateAssessment
    class InvalidXml < StandardError; end

    def execute(xml, schema_location)
      validate_xml(xml, schema_location)
    end

    private

    def validate_xml(xml, schema)
      xsddoc = Nokogiri.XML(File.read(schema), schema)
      xsd = Nokogiri::XML::Schema.from_document(xsddoc)
      file = Nokogiri.XML(xml)
      errors = xsd.validate(file)

      raise InvalidXml, errors.map(&:message).join(', ') if errors.any?

      true
    end
  end
end
