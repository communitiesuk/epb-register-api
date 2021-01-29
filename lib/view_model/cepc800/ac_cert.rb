module ViewModel
  module Cepc800
    class AcCert < ViewModel::Cepc800::CommonSchema
      def xpath(queries, node = @xml_doc)
        queries.each do |query|
          if node
            node = node.at query
          else
            return nil
          end
        end
        node ? node.content : nil
      end

      def building_complexity
        xpath(%w[Building-Complexity])
      end

      def f_gas_compliant_date
        xpath(%w[Air-Conditioning-Inspection-Certificate F-Gas-Compliant-Date])
      end

      def ac_rated_output
        xpath(%w[AC-Rated-Output AC-kW-Rating])
      end

      def random_sampling
        xpath(%w[Air-Conditioning-Inspection-Certificate Random-Sampling-Flag])
      end

      def treated_floor_area
        xpath(%w[Air-Conditioning-Inspection-Certificate Treated-Floor-Area])
      end

      def ac_system_metered
        xpath(
          %w[Air-Conditioning-Inspection-Certificate AC-System-Metered-Flag],
        )
      end

      def refrigerant_charge
        xpath(
          %w[Air-Conditioning-Inspection-Certificate Refrigerant-Charge-Total],
        )
      end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def subsystems
        @xml_doc.search("AC-Sub-System").select(&:element?).map { |node|
          {
            number: xpath(%w[Sub-System-Number], node),
            description: xpath(%w[Sub-System-Description], node),
            age: xpath(%w[Sub-System-Age], node),
            refrigerantType: xpath(%w[Refrigerant-Type], node),
          }
        }.compact
      end
    end
  end
end
