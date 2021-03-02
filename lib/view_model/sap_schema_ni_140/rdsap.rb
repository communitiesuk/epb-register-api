module ViewModel
  module SapSchemaNi140
    class Rdsap < ViewModel::SapSchemaNi140::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
