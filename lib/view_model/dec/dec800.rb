module ViewModel
  module Dec
    class Dec800 < ViewModel::Common::SchemaCepc800

      def energy_efficiency_rating
        xpath(%w[This-Assessment Energy-Rating])
      end

      def current_assessment_date
        xpath(%w[This-Assessment Nominated-Date])
      end

      def current_heating_co2
        xpath(%w[This-Assessment Heating-CO2])
      end

      def current_electricity_co2
        xpath(%w[This-Assessment Electricity-CO2])
      end

      def current_renewables_co2
        xpath(%w[This-Assessment Renewables-CO2])
      end

      def year1_assessment_date
        xpath(%w[Year1-Assessment Nominated-Date])
      end

      def year1_heating_co2
        xpath(%w[Year1-Assessment Heating-CO2])
      end

      def year1_electricity_co2
        xpath(%w[Year1-Assessment Electricity-CO2])
      end

      def year1_renewables_co2
        xpath(%w[Year1-Assessment Renewables-CO2])
      end

      def year1_energy_efficiency_rating
        xpath(%w[Year1-Assessment Energy-Rating])
      end

      def year2_assessment_date
        xpath(%w[Year2-Assessment Nominated-Date])
      end

      def year2_heating_co2
        xpath(%w[Year2-Assessment Heating-CO2])
      end

      def year2_electricity_co2
        xpath(%w[Year2-Assessment Electricity-CO2])
      end

      def year2_renewables_co2
        xpath(%w[Year2-Assessment Renewables-CO2])
      end

      def year2_energy_efficiency_rating
        xpath(%w[Year2-Assessment Energy-Rating])
      end

    end
  end
end
