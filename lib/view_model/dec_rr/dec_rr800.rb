module ViewModel
  module DecRr
    class DecRr800 < ViewModel::Common::SchemaCepc800
      def assessment_id
        xpath(%w[RRN])
      end

      def report_type
        xpath(%w[Report-Type])
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
    end
  end
end
