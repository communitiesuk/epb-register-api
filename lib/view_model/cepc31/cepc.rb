module ViewModel
  module Cepc31
    class Cepc < ViewModel::Cepc31::CommonSchema
      def ac_inspection_commissioned
        nil
      end

      def ac_kw_rating
        nil
      end

      def ac_present
        nil
      end

      def building_emission_rate
        nil
      end

      def building_emission
        nil
      end

      def building_environment
        xpath(%w[Building-Environment])
      end

      def building_level
        xpath(%w[Building-Level])
      end

      def energy_efficiency_rating
        xpath(%w[Asset-Rating])
      end

      def epc_related_party_disclosure
        xpath(%w[Related-Party-Disclosure])
      end

      def estimated_ac_kw_rating
        nil
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

      def new_build_rating
        xpath(%w[New-Build-Benchmark])
      end

      def other_fuel_description
        xpath(%w[Other-Fuel-Description])
      end

      def primary_energy_use
        xpath(%w[Energy-Consumption-Current])
      end

      def primary_energy_use
        nil
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def special_energy_uses
        xpath(%w[Special-Energy-Uses])
      end

      def standard_emissions
        nil
      end

      def target_emissions
        nil
      end

      def transaction_type
        nil
      end

      def typical_emissions
        nil
      end

      def renewable_sources
        xpath(%w[Renewable-Sources])
      end
    end
  end
end
