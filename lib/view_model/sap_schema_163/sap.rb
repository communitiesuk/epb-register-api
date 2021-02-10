module ViewModel
  module SapSchema163
    class Sap < ViewModel::SapSchema163::CommonSchema
      def assessor_name
        [
          xpath(%w[Home-Inspector Name Prefix]),
          xpath(%w[Home-Inspector Name First-Name]),
          xpath(%w[Home-Inspector Name Surname]),
          xpath(%w[Home-Inspector Name Suffix]),
        ].reject { |e| e.to_s.empty? }.join(" ")
      end

      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end
    end
  end
end
