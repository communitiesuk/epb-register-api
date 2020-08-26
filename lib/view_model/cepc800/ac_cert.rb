module ViewModel
  module Cepc800
    class AcCert < ViewModel::Cepc800::CommonSchema
      def building_complexity
        xpath(%w[Building-Complexity])
      end
    end
  end
end
