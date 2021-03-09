module ViewModel
  module SapSchema130
    class Rdsap < ViewModel::SapSchema130::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end

      def mechanical_ventilation
        xpath(%w[Mechanical-Ventilation])
      end
    end
  end
end
