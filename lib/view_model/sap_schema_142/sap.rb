module ViewModel
  module SapSchema142
    class Sap < ViewModel::SapSchema142::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
