# frozen_string_literal: true

module Helper
  class SanitizeXmlHelper
    def sanitize(xml)
      if xml.match?(/^\n/)
        xml = strip_newline_from_start(xml)
      end

      %w[Formatted-Report PDF].each do |tag_name|
        xml = strip_out_tag(tag_name, xml)
      end

      xml
    end

  private

    def strip_newline_from_start(xml)
      regex = %r{^\n}
      xml.sub(regex, "")
    end

    def strip_out_tag(tag_name, xml)
      regex = %r{[\s\r\n]*<#{tag_name}>(.|\n|\r)*</#{tag_name}>}
      xml.sub(regex, "")
    end
  end
end
