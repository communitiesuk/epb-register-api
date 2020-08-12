module ViewModel
  module Cepc800
    class Dec < ViewModel::Cepc800::CommonSchema
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

      def main_heating_fuel
        xpath(%w[HVAC-Systems HVAC-System-Data Fuel-Type])
      end

      def building_environment
        xpath(%w[Technical-Information Building-Environment])
      end

      def floor_area
        xpath(%w[Technical-Information Floor-Area])
      end

      def asset_rating
        xpath(%w[This-Assessment Energy-Rating])
      end

      def annual_energy_use_fuel_thermal
        xpath(%w[DEC-Annual-Energy-Summary Annual-Energy-Use-Fuel-Thermal])
      end

      def annual_energy_use_electrical
        xpath(%w[DEC-Annual-Energy-Summary Annual-Energy-Use-Electrical])
      end

      def typical_thermal_use
        xpath(%w[DEC-Annual-Energy-Summary Typical-Thermal-Use])
      end

      def typical_electrical_use
        xpath(%w[DEC-Annual-Energy-Summary Typical-Electrical-Use])
      end

      def renewables_fuel_thermal
        xpath(%w[DEC-Annual-Energy-Summary Renewables-Fuel-Thermal])
      end

      def renewables_electrical
        xpath(%w[DEC-Annual-Energy-Summary Renewables-Electrical])
      end

      def dec_related_party_disclosure
        xpath(%w[DEC-Related-Party-Disclosure])
      end

      def calculation_tool
        xpath(%w[Calculation-Details Calculation-Tool])
      end
    end
  end
end
