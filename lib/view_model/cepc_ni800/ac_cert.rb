module ViewModel
  module CepcNi800
    class AcCert < ViewModel::CepcNi800::CommonSchema
      def building_complexity
        xpath(%w[Building-Complexity])
      end
    end
  end
end
