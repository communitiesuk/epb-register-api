# frozen_string_literal: true

module Helper
  class SanitizeXmlHelper
    def sanitize(xml)
      %w[Formatted-Report PDF].each do |tag_name|
        xml = strip_out_tag(tag_name, xml)
      end

      xml
    end

  private

    def strip_out_tag(tag_name, xml)
      regex = %r{[\s\r\n]*<#{tag_name}>(.|\n|\r)*</#{tag_name}>}
      xml.sub(regex, "")
    end
  end
end
