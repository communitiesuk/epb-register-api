module ViewModel
  module Cepc
    class Cepc800
      def initialize(xml)
        @xml_doc = Nokogiri.XML(xml)
      end

      def assessment_id
        @xml_doc.at("//CEPC:RRN").content
      end
    end
  end
end
