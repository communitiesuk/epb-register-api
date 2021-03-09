module ViewModel
  module SapSchema142
    class Rdsap < ViewModel::SapSchema142::CommonSchema
      def property_age_band
        xpath(%w[Construction-Age-Band])
      end

      def mechanical_ventilation
        xpath(%w[Mechanical-Ventilation])
      end
    end
  end
end
