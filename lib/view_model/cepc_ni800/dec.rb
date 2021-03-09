module ViewModel
  module CepcNi800
    class Dec < ViewModel::CepcNi800::CommonSchema
      def date_of_expiry
        floor_area =
          xpath(%w[Display-Certificate Technical-Information Floor-Area])

        expiry_date = Date.parse(current_assessment_date)

        expiry_date =
          if floor_area.to_i <= 1000 && !postcode.start_with?("BT")
            (expiry_date - 1).next_year 10
          else
            (expiry_date - 1).next_year 1
          end

        expiry_date.strftime("%F")
      end

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
        xpath(%w[Technical-Information Main-Heating-Fuel])
      end

      def building_environment
        xpath(%w[Technical-Information Building-Environment])
      end

      def floor_area
        xpath(%w[Technical-Information Floor-Area])
      end

      def asset_rating
        xpath(%w[OR-Previous-Data Asset-Rating])
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

      def dec_status
        xpath(%w[DEC-Status])
      end

      def dec_related_party_disclosure
        xpath(%w[DEC-Related-Party-Disclosure])
      end

      def calculation_tool
        xpath(%w[Calculation-Details Calculation-Tool])
      end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def output_engine
        xpath(%w[Output-Engine])
      end

      def or_assessment_start_date
        xpath(%w[OR-Operational-Rating OR-Assessment-Start-Date])
      end

      def occupier
        xpath(%w[Occupier])
      end

      def benchmarks
        @xml_doc
          .search("Benchmarks/Benchmark")
          .map do |node|
            {
              name: xpath(%w[Name], node),
              id: xpath(%w[Benchmark-ID], node),
              tufa: xpath(%w[TUFA], node),
            }
          end
      end

      def or_energy_consumption
        @xml_doc
          .search("OR-Energy-Consumption")
          .children
          .select(&:element?)
          .map do |node|
            {
              consumption: xpath(%w[Consumption], node),
              start_date: xpath(%w[Start-Date], node),
              end_date: xpath(%w[End-Date], node),
              estimate: xpath(%w[Estimate], node),
              name: node.name,
            }
          end
      end

      def annual_energy_summary
        summary = @xml_doc.search("DEC-Annual-Energy-Summary")
        {
          electrical: xpath(%w[Annual-Energy-Use-Electrical], summary),
          fuel_thermal: xpath(%w[Annual-Energy-Use-Fuel-Thermal], summary),
          renewables_fuel_thermal: xpath(%w[Renewables-Fuel-Thermal], summary),
          renewables_electrical: xpath(%w[Renewables-Electrical], summary),
          typical_thermal_use: xpath(%w[Typical-Thermal-Use], summary),
          typical_electrical_use: xpath(%w[Typical-Electrical-Use], summary),
        }
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def main_benchmark
        xpath(%w[OR-Benchmark-Data Main-Benchmark])
      end

      def special_energy_uses
        xpath(%w[Technical-Information Special-Energy-Uses])
      end

      def occupancy_level
        xpath(%w[Benchmarks Benchmark Occupancy-Level])
      end

      def ac_inspection_commissioned
        xpath(%w[AC-Inspection-Commissioned])
      end

      def ac_present
        xpath(%w[AC-Present])
      end

      def ac_kw_rating
        xpath(%w[AC-kW-Rating])
      end

      def estimated_ac_kw_rating
        xpath(%w[AC-Estimated-Output])
      end

      def building_category
        xpath(%w[Building-Category])
      end

      def other_fuel
        xpath(%w[Technical-Information Other-Fuel-Description])
      end
    end
  end
end
