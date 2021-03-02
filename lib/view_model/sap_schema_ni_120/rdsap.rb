module ViewModel
  module SapSchemaNi120
    class Rdsap < ViewModel::SapSchemaNi120::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
