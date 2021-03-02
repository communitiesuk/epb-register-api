module ViewModel
  module SapSchemaNi150
    class Rdsap < ViewModel::SapSchemaNi150::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
