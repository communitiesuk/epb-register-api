module ViewModel
  module SapSchema112
    class Rdsap < ViewModel::SapSchema112::CommonSchema
      def property_age_band
        nil
      end

      # DO NOT CORRECT - this typo is present in the schema XML pre 12.0
      def mechanical_ventilation
        xpath(%w[Mechanical-Ventliation])
      end
    end
  end
end
