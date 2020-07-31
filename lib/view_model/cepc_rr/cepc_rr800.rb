module ViewModel
  module CepcRr
    class CepcRr800
      def initialize(xml)
        @xml_doc = Nokogiri.XML xml
      end

      def xpath(queries)
        node = @xml_doc
        queries.each { |query| node = node.at query }
        node ? node.content : nil
      end

      def assessment_id
        xpath(%w[RRN])
      end

      def report_type
        xpath(%w[Report-Type])
      end
    end
  end
end
