module ViewModel
  module Dec
    class Dec800 < ViewModel::Common::SchemaCepc800

      def assessment_id
        xpath(%w[RRN])
      end

      def date_of_expiry
        xpath(%w[Valid-Until])
      end

      def address_line1
        xpath(%w[Property-Address Address-Line-1])
      end

      def address_line2
        xpath(%w[Property-Address Address-Line-2])
      end

      def address_line3
        xpath(%w[Property-Address Address-Line-3])
      end

      def address_line4
        xpath(%w[Property-Address Address-Line-4])
      end

      def town
        xpath(%w[Property-Address Post-Town])
      end

      def postcode
        xpath(%w[Property-Address Postcode])
      end

      def energy_efficiency_rating
        xpath(%w[This-Assessment Energy-Rating])
      end

      def report_type
        xpath(%w[Report-Type])
      end

      def address_id
        xpath(%w[UPRN])
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
