module ViewModel
  module SapSchemaNi141
    class Rdsap < ViewModel::SapSchemaNi141::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
