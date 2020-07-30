module ViewModel
  module Cepc
    class Cepc800
      def initialize(xml)
        @xml_doc = Nokogiri.XML(xml)
      end

      def xpath(queries)
        node = @xml_doc
        queries.each { |query| node = node.at(query) }
        node ? node.content : nil
      end

      def assessment_id
        xpath(%w[//CEPC:RRN])
      end

      def date_of_expiry
        xpath(%w[//CEPC:Valid-Until])
      end

      def address_line1
        xpath(%w[//CEPC:Property-Address //CEPC:Address-Line-1])
      end

      def address_line2
        xpath(%w[//CEPC:Property-Address //CEPC:Address-Line-2])
      end

      def address_line3
        xpath(%w[//CEPC:Property-Address //CEPC:Address-Line-3])
      end

      def address_line4
        xpath(%w[//CEPC:Property-Address //CEPC:Address-Line-4])
      end

      def town
        xpath(%w[//CEPC:Property-Address //CEPC:Post-Town])
      end

      def postcode
        xpath(%w[//CEPC:Property-Address //CEPC:Postcode])
      end

      def main_heating_fuel
        xpath(%w[//CEPC:Main-Heating-Fuel])
      end

      def building_environment
        xpath(%w[//CEPC:Building-Environment])
      end
    end
  end
end
