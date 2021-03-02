module ViewModel
  module SapSchemaNi170
    class Rdsap < ViewModel::SapSchemaNi170::CommonSchema
      def assessor_name
        xpath(%w[Home-Inspector Name])
      end

      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
