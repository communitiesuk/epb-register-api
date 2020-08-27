module ViewModel
  module CepcNi800
    class AcReport < ViewModel::CepcNi800::CommonSchema
      def related_party_disclosure
        xpath(%w[ACI-Related-Party-Disclosure])
      end
    end
  end
end
