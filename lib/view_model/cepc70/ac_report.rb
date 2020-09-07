module ViewModel
  module Cepc70
    class AcReport < ViewModel::Cepc70::CommonSchema
      def related_party_disclosure
        xpath(%w[ACI-Related-Party-Disclosure])
      end

      def executive_summary
        xpath(%w[Executive-Summary])
      end
      def equipment_owner_name
        xpath(%w[Equipment-Owner Equipment-Owner-Name])
      end

      def equipment_owner_telephone
        xpath(%w[Equipment-Owner Telephone-Number])
      end

      def equipment_owner_organisation
        xpath(%w[Equipment-Owner Organisation-Name])
      end

      def equipment_owner_address_line1
        xpath(%w[Equipment-Owner Registered-Address Address-Line-1])
      end

      def equipment_owner_address_line2
        xpath(%w[Equipment-Owner Registered-Address Address-Line-2])
      end

      def equipment_owner_address_line3
        xpath(%w[Equipment-Owner Registered-Address Address-Line-3])
      end

      def equipment_owner_address_line4
        xpath(%w[Equipment-Owner Registered-Address Address-Line-4])
      end

      def equipment_owner_town
        xpath(%w[Equipment-Owner Registered-Address Post-Town])
      end

      def equipment_owner_postcode
        xpath(%w[Equipment-Owner Registered-Address Postcode])
      end

    end
  end
end
