module ViewModel
  module SapSchema120
    class Sap < ViewModel::SapSchema120::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
