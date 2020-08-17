module ViewModel
  module Cepc800
    class DecRr < ViewModel::Cepc800::CommonSchema
      def floor_area
        xpath(%w[Advisory-Report Technical-Information Floor-Area])
      end

      def building_environment
        xpath(%w[Advisory-Report Technical-Information Building-Environment])
      end
    end
  end
end
