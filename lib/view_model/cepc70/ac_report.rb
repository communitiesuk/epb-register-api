module ViewModel
  module Cepc70
    class AcReport < ViewModel::Cepc70::CommonSchema
      def related_party_disclosure
        xpath(%w[ACI-Related-Party-Disclosure])
      end
    end
  end
end
