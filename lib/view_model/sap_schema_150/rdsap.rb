module ViewModel
  module SapSchema150
    class Rdsap < ViewModel::SapSchema150::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
