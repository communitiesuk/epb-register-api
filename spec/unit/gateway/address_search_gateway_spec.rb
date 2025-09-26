describe Gateway::AddressSearchGateway do
  subject(:gateway) { described_class.new }

  include RSpecRegisterApiServiceMixin

  context "when an address from address_base is returned in an address search response" do
    before do
      insert_into_address_base(
        "1234123417777777",
        "EH1 2NG",
        "2 MCDONALD ROAD",
        "SHELDSTOWN",
        "BOARDERS",
        "S",
      )

      insert_into_address_base(
        "1234123412323232",
        "SE1 7EF",
        "1 MCDONALD ROAD",
        "SHELDSTOWN",
        "LONDON",
        "E",
      )
    end

    it "returns an English property when searched by postcode" do
      address = gateway.search_by_postcode("SE1 7EF", nil, nil).first.line1
      expect(address).to eq "1 McDonald Road"
    end

    it "does not return the address for Scottish property when searched by postcode" do
      address = gateway.search_by_postcode("EH1 2NG", nil, nil)
      expect(address).to eq []
    end

    it "returns an English property when searched by address_id" do
      address = gateway.search_by_address_id("UPRN-1234123412323232").first.line1
      expect(address).to eq "1 McDonald Road"
    end

    it "does not return the address for Scottish property when searched by address_id" do
      address = gateway.search_by_address_id("UPRN-1234123417777777")
      expect(address).to eq []
    end

    it "returns an English property when searched by streen name and town" do
      address = gateway.search_by_street_and_town("1 MCDONALD ROAD", "LONDON", nil).first.line1
      expect(address).to eq "1 McDonald Road"
    end

    it "does not return the address for Scottish property when searched by streen name and town" do
      address = gateway.search_by_street_and_town("2 MCDONALD ROAD", "BOARDERS", nil)
      expect(address).to eq []
    end
  end
end
