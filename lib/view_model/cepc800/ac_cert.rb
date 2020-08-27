module ViewModel
  module Cepc800
    class AcCert < ViewModel::Cepc800::CommonSchema
      def building_complexity
        xpath(%w[Building-Complexity])
      end

      def f_gas_compliant_date
        xpath(%w[Air-Conditioning-Inspection-Certificate F-Gas-Compliant-Date])
      end

      def ac_rated_output
        xpath(%w[AC-Rated-Output AC-kW-Rating])
      end

      def treated_floor_area
        xpath(%w[Air-Conditioning-Inspection-Certificate Treated-Floor-Area])
      end
    end
  end
end
