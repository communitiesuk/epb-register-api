# frozen_string_literal: true

module Helper
  class SanitizeXmlHelper
    def sanitize(xml)
      sanitized_xml = xml.sub(/<Formatted-Report>.*<\/Formatted-Report>/, "")
      sanitized_xml
    end
  end
end
