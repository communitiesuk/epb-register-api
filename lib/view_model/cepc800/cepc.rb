module ViewModel
  module Cepc800
    class Cepc < ViewModel::Cepc800::CommonSchema
      def ac_inspection_commissioned
        xpath(%w[AC-Inspection-Commissioned])
      end

      def ac_kw_rating
        xpath(%w[AC-kW-Rating])
      end

      def ac_present
        xpath(%w[AC-Present])
      end

      def building_emissions
        xpath(%w[BER])
      end

      # This would seem to be a copy? Is the method name used?
      def building_emission_rate
        xpath(%w[BER])
      end

      def building_environment
        xpath(%w[Building-Environment])
      end

      def building_level
        xpath(%w[Building-Level])
      end

      # Is this used?
      def effective_date
        xpath(%w[Effective-Date])
      end

      def energy_efficiency_rating
        xpath(%w[Asset-Rating])
      end

      def epc_related_party_disclosure
        xpath(%w[EPC-Related-Party-Disclosure])
      end

      def estimated_ac_kw_rating
        xpath(%w[AC-Estimated-Output])
      end

      def existing_build_rating
        xpath(%w[Existing-Stock-Benchmark])
      end

      def floor_area
        xpath(%w[Technical-Information Floor-Area])
      end

      def main_heating_fuel
        xpath(%w[Main-Heating-Fuel])
      end

      # This is new_build_benchmark in the CEPC wrapper
      def new_build_rating
        xpath(%w[New-Build-Benchmark])
      end

      def or_assessment_start_date
        xpath(%w[OR-Operational-Rating OR-Assessment-Start-Date])
      end

      def or_availability_date
        xpath(%w[Technical-Information OR-Availability-Date])
      end

      def other_fuel_description
        xpath(%w[Other-Fuel-Description])
      end

      def primary_energy_use
        xpath(%w[Energy-Consumption-Current])
      end

      def property_type
        xpath(%w[Property-Type])
      end

      # Is this used in the CEPC wrapper?
      # def renewable_energy_source
      #   xpath(%w[Renewable-Energy-Source])
      # end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def special_energy_uses
        xpath(%w[Special-Energy-Uses])
      end

      def standard_emissions
        xpath(%w[SER])
      end

      def target_emissions
        xpath(%w[TER])
      end

      def transaction_type
        xpath(%w[Transaction-Type])
      end

      def typical_emissions
        xpath(%w[TYR])
      end

      def renewable_sources
        xpath(%w[Renewable-Sources])
      end
    end
  end
end
