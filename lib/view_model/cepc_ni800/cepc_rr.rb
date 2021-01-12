module ViewModel
  module CepcNi800
    class CepcRr < ViewModel::CepcNi800::CommonSchema
      def recommendations(payback = "")
        if payback.empty?
          @xml_doc.search(%w[RR-Recommendations]).map { |node| node }
        else
          @xml_doc
            .search("RR-Recommendations/#{payback}")
            .map do |node|
              {
                code: node.at("Recommendation-Code").content,
                text: node.at("Recommendation").content,
                cO2Impact: node.at("CO2-Impact").content,
              }
            end
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
        xpath(%w[Technical-Information Floor-Area])
      end

      def building_environment
        xpath(%w[Building-Environment])
      end

      def calculation_tools
        xpath(%w[Calculation-Tool])
      end

      def related_certificate
        xpath(%w[Related-RRN])
      end

      def related_party_disclosure
        xpath(%w[Related-Party-Disclosure])
      end
    end
  end
end
