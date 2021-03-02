module ViewModel
  module SapSchemaNi142
    class Rdsap < ViewModel::SapSchemaNi142::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
