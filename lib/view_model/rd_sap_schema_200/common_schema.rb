module ViewModel
  module RdSapSchema200
    class CommonSchema
      def initialize(xml)
        @xml_doc = Nokogiri.XML xml
      end

      def xpath(queries)
        node = @xml_doc
        queries.each { |query| node = node.at query }
        node ? node.content : nil
      end

      def habitable_room_count
        xpath(%w[Habitable-Room-Count])
      end

      def energy_rating_current
        xpath(%w[Energy-Rating-Current])
      end

      def energy_rating_potential
        xpath(%w[Energy-Rating-Potential])
      end

      def environmental_impact_current
        xpath(%w[Environmental-Impact-Current])
      end

      def environmental_impact_potential
        xpath(%w[Environmental-Impact-Potential])
      end

      def all_wall_descriptions
        @xml_doc.search("Wall/Description").map(&:content)
      end

      def all_roof_descriptions
        @xml_doc.search("Roof/Description").map(&:content)
      end

      def all_floor_descriptions
        @xml_doc.search("Floor/Description").map(&:content)
      end

      def all_window_descriptions
        @xml_doc.search("Window/Description").map(&:content)
      end

      def all_main_heating_descriptions
        @xml_doc.search("Main-Heating/Description").map(&:content)
      end

      def all_main_heating_controls_descriptions
        @xml_doc.search("Main-Heating-Controls/Description").map(&:content)
      end

      def all_hot_water_descriptions
        @xml_doc.search("Hot-Water/Description").map(&:content)
      end

      def all_lighting_descriptions
        @xml_doc.search("Lighting/Description").map(&:content)
      end

      def all_secondary_heating_descriptions
        @xml_doc.search("Secondary-Heating/Description").map(&:content)
      end
    end
  end
end
