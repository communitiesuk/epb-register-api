module ViewModel
  module SapSchema141
    class Rdsap < ViewModel::SapSchema141::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
