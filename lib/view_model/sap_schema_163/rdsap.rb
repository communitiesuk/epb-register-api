module ViewModel
  module SapSchema163
    class Rdsap < ViewModel::SapSchema163::CommonSchema
      def assessor_name
        xpath(%w[Home-Inspector Name])
      end

      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
