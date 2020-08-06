module ViewModel
  module Cepc
    class Cepc800 < ViewModel::Common::SchemaCepc800
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

      def scheme_assessor_id
        xpath(%w[Certificate-Number])
      end

      def assessor_name
        xpath(%w[Energy-Assessor Name])
      end

      def assessor_email
        xpath(%w[Energy-Assessor E-Mail])
      end

      def assessor_telephone
        xpath(%w[Energy-Assessor Telephone-Number])
      end

      def company_name
        xpath(%w[Energy-Assessor Company-Name])
      end

      def company_address
        xpath(%w[Energy-Assessor Trading-Address])
      end


      def date_of_assessment
        xpath(%w[Inspection-Date])
      end

      def date_of_registration
        xpath(%w[Registration-Date])
      end

      def date_of_issue
        xpath(%w[Issue-Date])
      end

      def epc_related_party_disclosure
        xpath(%w[EPC-Related-Party-Disclosure])
      end

      def address_id
        xpath(%w[UPRN])
      end

      def property_type
        xpath(%w[Property-Type])
      end

      def effective_date
        xpath(%w[Effective-Date])
      end

      def or_availability_date
        xpath(%w[Technical-Information OR-Availability-Date])
      end

      def or_assessment_start_date
        xpath(%w[OR-Operational-Rating OR-Assessment-Start-Date])
      end

      def start_dates
        @xml_doc.search("Start-Date").map(&:content)
      end

      def all_floor_areas
        @xml_doc.search("Floor-Area").map(&:content)
      end

      def all_energy_types
        @xml_doc.search("Energy-Type").map(&:content)
      end

      def standard_emissions
        xpath(%w[SER])
      end

      def building_emissions
        xpath(%w[BER])
      end

      def target_emissions
        xpath(%w[TER])
      end

      def typical_emissions
        xpath(%w[TYR])
      end

      def transaction_type
        xpath(%w[Transaction-Type])
      end
    end
  end
end
