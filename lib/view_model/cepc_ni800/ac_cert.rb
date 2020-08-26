module ViewModel
  module CepcNi800
    class AcCert < ViewModel::CepcNi800::CommonSchema
      def building_complexity
        xpath(%w[Building-Complexity])
      end

      def f_gas_compliant_date
        xpath(%w[Air-Conditioning-Inspection-Certificate F-Gas-Compliant-Date])
      end
    end
  end
end
