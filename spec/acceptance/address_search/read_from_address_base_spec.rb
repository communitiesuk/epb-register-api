describe "reading out from address_base table" do
  include RSpecRegisterApiServiceMixin

  context "when an address from address_base is returned in an address search response" do
    before do
      insert_into_address_base(
        "UPRN-1234123412341234",
        "A0 0AA",
        "1 MCDONALD ROAD",
        "O'BRIENSTOWN",
        "ANYTOWN",
      )
    end

    it "returns the address with the address street lines title cased" do
      address = Gateway::AddressBaseSearchGateway.new.search_by_uprn("UPRN-1234123412341234").first
      expect(%i[line1 line2 town].map { |method| address.send method }).to eq [
        "1 McDonald Road",
        "O'Brienstown",
        "ANYTOWN",
      ]
    end
  end
end
