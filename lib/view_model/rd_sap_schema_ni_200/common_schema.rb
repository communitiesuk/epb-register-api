module ViewModel
  module RdSapSchemaNi200
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
    end
  end
end
