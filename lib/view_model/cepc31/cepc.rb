module ViewModel
  module Cepc31
    class Cepc < ViewModel::Cepc31::CommonSchema
      def main_heating_fuel
        xpath(%w[Main-Heating-Fuel])
      end

      def building_environment
        xpath(%w[Building-Environment])
      end

      def floor_area
        xpath(%w[Technical-Information Floor-Area])
      end

      def building_level
        xpath(%w[Building-Level])
      end

      def building_emission_rate
        nil
      end

      def primary_energy_use
        xpath(%w[Energy-Consumption-Current])
      end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def new_build_rating
        xpath(%w[New-Build-Benchmark])
      end

      def existing_build_rating
        xpath(%w[Existing-Stock-Benchmark])
      end

      def energy_efficiency_rating
        xpath(%w[Asset-Rating])
      end

      def epc_related_party_disclosure
        xpath(%w[Related-Party-Disclosure])
      end

      def building_emission
        nil
      end

      def building_emission_rate
        nil
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def ac_present
        nil
      end

      def transaction_type
        nil
      end

      def other_fuel_description
        nil
      end

      def target_emissions
        nil
      end

      def typical_emissions
        nil
      end

      def ac_kw_rating
        nil
      end

      def estimated_ac_kw_rating
        nil
      end

      def special_energy_uses
        xpath(%w[Special-Energy-Uses])
      end

      def standard_emissions
        nil
      end

      def ac_inpsection_commissioned
        nil
      end

      def primary_energy_use
        nil
      end
    end
  end
end
