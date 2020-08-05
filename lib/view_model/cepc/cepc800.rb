module ViewModel
  module Cepc
    class Cepc800
      def initialize(xml)
        @xml_doc = Nokogiri.XML xml
      end

      def xpath(queries)
        node = @xml_doc
        queries.each { |query| node = node.at query }
        node ? node.content : nil
      end

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

      def main_heating_fuel
        xpath(%w[Main-Heating-Fuel])
      end

      def building_environment
        xpath(%w[Building-Environment])
      end

      def floor_area
        xpath(%w[Floor-Area])
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

      def report_type
        xpath(%w[Report-Type])
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

      def related_party_disclosure
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
    end
  end
end
