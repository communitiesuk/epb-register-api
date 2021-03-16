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

    # def construction_age_band
    #   building_part_number_node_set =
    #     @xml_doc.xpath("//*[local-name() = 'Building-Part-Number']")
    #   building_part_parent =
    #     building_part_number_node_set.find{ |node|
    #       node.content == "1"
    #     }&.parent
    #   building_part_parent&.search("Construction-Age-Band")&.first&.content
    # end
    #
    # If SAP-BUILDING-PART contains BUILDING-PART-NUMBER
    #   If hat BUILDING-PART-NUMBER has a value of 1
    #    Check whether that SAP-BUILDING-PART has a CAB or a CY as a sibling to BPN
    #      If SAP-BUILDING-PART has a CAB, return enum value
    #      Else return CY value
    #
    # -------------------------------------------------------
    # def construction_age_band
    #   sap_building_part_node_set = @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
    #   sap_building_part_node_set.each do |sap_building_part|
    #
    #     if sap_building_part.search("Building-Part-Number")
    #       pp "SAP BUILDING PART Exists!"
    #
    #       if sap_building_part
    #          .search("Building-Part-Number")
    #          .map(&:content)
    #          .include?("1")
    #
    #         pp "CAB!!!!!!!!!!!!!!!"
    #         # Below returns empty array
    #         pp sap_building_part.search("Construction-Age-Band").children
    #
    #         if !sap_building_part.search("Construction-Age-Band").empty?
    #           pp "Construction Age Band Exists!"
    #           return sap_building_part.search("Construction-Age-Band").children[0].to_s
    #         end
    #
    #         if sap_building_part.search("Construction-Year")
    #           pp "Construction Year Exists!"
    #           return sap_building_part.search("Construction-Year").children[0].to_s
    #         end
    #       end
    #     end
    #   end
    # end
    # -------------------------------------------------------
    #
    # def construction_age_band
    #   building_parts = @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
    #   building_parts.each do |building_part|
    #     if building_part
    #            .search("Building-Part-Number")
    #            .map(&:content)
    #            .include?("1")
    #       return building_part.search("Construction-Age-Band").children[0].to_s
    #     end
    #   end
    # end



    def property_type
      xpath(%w[Property-Type])
    end

    def multi_glazing_type
      xpath(%w[Multiple-Glazing-Type])
    end
  end
end
