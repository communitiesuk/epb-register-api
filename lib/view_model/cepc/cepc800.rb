module ViewModel
  module Cepc
    class Cepc800
      def initialize(xml)
        @xml_doc = Nokogiri.XML(xml)
      end

      def xpath(queries)
        node = @xml_doc
        queries.each do |query|
          node = node.at(query)
        end
        node ? node.content : nil
      end

      def assessment_id
        xpath(["//CEPC:RRN"])
      end

      def date_of_expiry
        xpath(["//CEPC:Valid-Until"])
      end

      def address_line1
        xpath(["//CEPC:Property-Address", "//CEPC:Address-Line-1"])
      end

      def address_line2
        xpath(["//CEPC:Property-Address", "//CEPC:Address-Line-2"])
      end

      def address_line3
        xpath(["//CEPC:Property-Address", "//CEPC:Address-Line-3"])
      end

      def address_line4
        xpath(["//CEPC:Property-Address", "//CEPC:Address-Line-4"])
      end

      def town
        xpath(["//CEPC:Property-Address", "//CEPC:Post-Town"])
      end

      def postcode
        xpath(["//CEPC:Property-Address", "//CEPC:Postcode"])
      end
    end
  end
end
