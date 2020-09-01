module ViewModel
  module Cepc71
    class AcReport < ViewModel::Cepc71::CommonSchema
      def related_party_disclosure
        xpath(%w[ACI-Related-Party-Disclosure])
      end
    end
  end
end
