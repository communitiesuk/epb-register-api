module ViewModel
  module SapSchemaNi140
    class Sap < ViewModel::SapSchemaNi140::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
