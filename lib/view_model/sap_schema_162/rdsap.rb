module ViewModel
  module SapSchema162
    class Rdsap < ViewModel::SapSchema162::CommonSchema
      def assessor_name
        xpath(%w[Home-Inspector Name])
      end

      def tenure
        xpath(%w[Tenure])
      end

      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end