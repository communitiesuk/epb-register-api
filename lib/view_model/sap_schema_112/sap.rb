module ViewModel
  module SapSchema112
    class Sap < ViewModel::SapSchema112::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
