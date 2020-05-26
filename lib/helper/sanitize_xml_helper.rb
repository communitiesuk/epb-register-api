# frozen_string_literal: true

module Helper
  class SanitizeXmlHelper
    def sanitize(xml)
      %w[Formatted-Report Unstructured-Data].each do |tag_name|
        xml = strip_out_tag(tag_name, xml)
      end

      xml
    end

  private

    def strip_out_tag(tag_name, xml)
      regex = /<#{tag_name}>(.|\n|\r)*<\/#{tag_name}>/
      xml = xml.sub(regex, "")
    end
  end
end
