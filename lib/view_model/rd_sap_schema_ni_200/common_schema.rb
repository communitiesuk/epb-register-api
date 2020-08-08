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
    end
  end
end
