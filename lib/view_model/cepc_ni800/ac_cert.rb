module ViewModel
  module CepcNi800
    class AcCert < ViewModel::CepcNi800::CommonSchema
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
    end
  end
end
