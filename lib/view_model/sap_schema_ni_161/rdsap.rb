module ViewModel
  module SapSchemaNi161
    class Rdsap < ViewModel::SapSchemaNi161::CommonSchema
      def assessor_name
        xpath(%w[Home-Inspector Name])
      end

      def property_age_band
        xpath(%w[Construction-Age-Band])
      end
    end
  end
end
