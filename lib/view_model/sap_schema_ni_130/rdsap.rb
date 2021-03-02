module ViewModel
  module SapSchemaNi130
    class Rdsap < ViewModel::SapSchemaNi130::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
