module ViewModel
  module SapSchemaNi141
    class Sap < ViewModel::SapSchemaNi141::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
