module ViewModel
  module Cepc800
    class DecRr < ViewModel::Cepc800::CommonSchema
      def recommendations(payback)
        @xml_doc.search("AR-Recommendations/#{payback}").map do |node|
          {
            code: node.at("Recommendation-Code").content,
            text: node.at("Recommendation").content,
            cO2Impact: node.at("CO2-Impact").content,
          }
        end
      end

      def short_payback_recommendations
        recommendations("Short-Payback")
      end

      def medium_payback_recommendations
        recommendations("Medium-Payback")
      end

      def long_payback_recommendations
        recommendations("Long-Payback")
      end

      def other_recommendations
        recommendations("Other-Payback")
      end

      def floor_area
        xpath(%w[Advisory-Report Technical-Information Floor-Area])
      end

      def building_environment
        xpath(%w[Advisory-Report Technical-Information Building-Environment])
      end
    end
  end
end
