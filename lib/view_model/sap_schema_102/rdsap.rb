module ViewModel
  module SapSchema102
    class Rdsap < ViewModel::SapSchema102::CommonSchema
      def property_age_band
        nil
      end

      def construction_age_band
        xpath(%w[Construction-Year])
      end

      # DO NOT CORRECT - this typo is present in the schema XML pre 12.0
      def mechanical_ventilation
        xpath(%w[Mechanical-Ventliation])
      end
    end
  end
end
