describe Gateway::AddressBaseSearchGateway do
  context "when given a UPRN to check existence" do
    it "returns false if there are no results from a UPRN search" do
      gateway = Gateway::AddressBaseSearchGateway.new
      def gateway.search_by_uprn(_uprn)
        []
      end
      expect(gateway.check_uprn_exists("0000-0000-0000-0023")).to be false
    end
    it "returns true if there are one or more results from a UPRN search" do
      gateway = Gateway::AddressBaseSearchGateway.new
      def gateway.search_by_uprn(uprn)
        [OpenStruct.new(address_id: uprn)]
      end
      expect(gateway.check_uprn_exists("0000-1111-2222-3333")).to be true
    end
  end
end
