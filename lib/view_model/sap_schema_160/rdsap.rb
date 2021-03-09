module ViewModel
  module SapSchema160
    class Rdsap < ViewModel::SapSchema160::CommonSchema
      def assessor_name
        xpath(%w[Home-Inspector Name])
      end

      def property_age_band
        xpath(%w[Construction-Age-Band])
      end

      def mechanical_ventilation
        xpath(%w[Mechanical-Ventilation])
      end
    end
  end
end
