module ViewModel
  module Cepc51
    class Cepc < ViewModel::Cepc51::CommonSchema
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
        xpath(%w[BER])
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
        xpath(%w[EPC-Related-Party-Disclosure])
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def ac_present
        xpath(%w[AC-Present])
      end

      def transaction_type
        xpath(%w[Transaction-Type])
      end

      def other_fuel_description
        nil
      end

    end
  end
end
