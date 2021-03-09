module ViewModel
  module SapSchema102
    class Rdsap < ViewModel::SapSchema102::CommonSchema
      def property_age_band
        nil
      end

      def construction_age_band
        xpath(%w[Construction-Year])
      end
    end
  end
end
