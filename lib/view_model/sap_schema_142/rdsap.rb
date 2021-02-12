module ViewModel
  module SapSchema142
    class Rdsap < ViewModel::SapSchema142::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
