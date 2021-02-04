module ViewModel
  module CepcNi800
    class CommonSchema < ViewModel::BaseViewModel
      def assessment_id
        xpath(%w[RRN])
      end

      def date_of_expiry
        xpath(%w[Valid-Until])
      end

      def report_type
        xpath(%w[Report-Type])
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

      def address_id
        xpath(%w[UPRN])
      end

      def all_start_dates
        @xml_doc.search("Start-Date").map(&:content)
      end

      def all_energy_types
        @xml_doc.search("Energy-Type").map(&:content)
      end

      def all_reason_types
        @xml_doc.search("Reason-Type").map(&:content)
      end

      def or_assessment_end_date
        xpath(%w[OR-Operational-Rating OR-Assessment-End-Date])
      end

      def calculation_tool
        xpath(%w[Calculation-Details Calculation-Tool])
      end

      def inspection_type
        xpath(%w[Calculation-Details Inspection-Type])
      end

      def building_level
        xpath(%w[Building-Level])
      end
    end
  end
end
