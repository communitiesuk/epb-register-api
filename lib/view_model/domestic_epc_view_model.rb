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
      building_part_number_node_set =
        @xml_doc.xpath("//*[local-name() = 'Building-Part-Number']")
      building_part_parent =
        building_part_number_node_set.select { |node|
          node.content == "1"
        }.first.parent
      building_part_parent&.search("Construction-Age-Band")&.first&.content
    end

    def property_type
      xpath(%w[Property-Type])
    end

    def multi_glazing_type
      xpath(%w[Multiple-Glazing-Type])
    end
  end
end
