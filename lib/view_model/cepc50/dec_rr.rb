module ViewModel
  module Cepc50
    class DecRr < ViewModel::Cepc50::CommonSchema
      def date_of_expiry
        floor_area = xpath(%w[Advisory-Report Technical-Information Floor-Area])

        expiry_date = Date.parse(date_of_issue)

        expiry_date =
          if floor_area.to_f <= 1000 && !postcode.start_with?("BT")
            (expiry_date - 1).next_year 10
          else
            (expiry_date - 1).next_year 7
          end

        expiry_date.strftime("%F")
      end

      def recommendations(payback)
        @xml_doc
          .search("AR-Recommendations/#{payback}")
          .map do |node|
            {
              code: node.at("Recommendation-Code").content,
              text: node.at("Recommendation").content,
              cO2Impact: node.at("CO2-Impact").content,
            }
          end
      end

      def site_services(service)
        {
          description:
            @xml_doc.at("Site-Services/#{service}/Description").content,
          quantity: @xml_doc.at("Site-Services/#{service}/Quantity").content,
        }
      end

      def site_service_one
        site_services("Service-1")
      end

      def site_service_two
        site_services("Service-2")
      end

      def site_service_three
        site_services("Service-3")
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

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def occupier
        xpath(%w[Occupier])
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def renewable_sources
        xpath(%w[Renewable-Sources])
      end

      def discounted_energy
        xpath(%w[Special-Energy-Uses])
      end
    end
  end
end
