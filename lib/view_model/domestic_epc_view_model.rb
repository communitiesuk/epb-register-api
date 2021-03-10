module ViewModel
  class DomesticEpcViewModel < ViewModel::BaseViewModel
    def initialize(xml)
      super(xml)
    end

    def improvement_title(node)
      # The SAP and RdSAP XSDs say
      # Text to precede the improvement description.
      # If 'Improvement-Heading' is not provided the 'Improvement-Summary' is used instead
      # If 'Improvement-Summary' is not provided the 'Improvement' is used instead
      return "" unless node

      title =
        [
          xpath(%w[Improvement-Heading], node),
          xpath(%w[Improvement-Summary], node),
          xpath(%w[Improvement], node),
        ].compact.delete_if(&:empty?).first || ""

      title = "" if title.to_i.to_s == title

      title
    end

    def construction_age_band
      building_parts = @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
      building_parts.each do |building_part|
        if building_part
             .search("Building-Part-Number")
             .map(&:content)
             .include?("1")
          return building_part.search("Construction-Age-Band").children[0].to_s
        end
      end
    end

    def property_type
      xpath(%w[Property-Type])
    end

    def multi_glazing_type
      xpath(%w[Multiple-Glazing-Type])
    end
  end
end
