module ViewModel
  module CepcRr
    class CepcRr800 < ViewModel::Common::SchemaCepc800
      def recommendations(payback)
        @xml_doc.search("RR-Recommendations/#{payback}").map do |node|
          {
            code: node.at("Recommendation-Code").content,
            text: node.at("Recommendation").content,
            cO2Impact: node.at("CO2-Impact").content,
          }
        end
      end

      def address_id
        xpath(%w[UPRN])
      end

      def scheme_assessor_id
        xpath(%w[Certificate-Number])
      end

      def assessor_name
        xpath(%w[Energy-Assessor Name])
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

      def date_of_registration
        xpath(%w[Registration-Date])
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

      def company_address
        xpath(%w[Trading-Address])
      end

      def company_name
        xpath(%w[Company-Name])
      end
    end
  end
end
