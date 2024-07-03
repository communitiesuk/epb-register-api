describe Gateway::AddressBaseCountryGateway do
  subject(:gateway) { described_class.new }

  context "when looking up country by UPRN" do
    before do
      add_address_base uprn: "12345", postcode: "SA1 1AA", country_code: "W"
      add_address_base uprn: "67890", postcode: "LS1 1AA", country_code: "E"
      add_address_base uprn: "24680", postcode: "BT1 1AA", country_code: "N"
    end

    context "with a simple UPRN reference without the UPRN prefix or zero padding" do
      it "gets a lookup that is a match and is known to be in Wales", :aggregate_failures do
        lookup = gateway.lookup_from_uprn "12345"
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be true
      end

      it "gets a lookup that is a match and is known to be in England", :aggregate_failures do
        lookup = gateway.lookup_from_uprn "67890"
        expect(lookup.match?).to be true
        expect(lookup.in_england?).to be true
      end

      it "gets a lookup that is a match and is known to be in Northern Ireland", :aggregate_failures do
        lookup = gateway.lookup_from_uprn "24680"
        expect(lookup.match?).to be true
        expect(lookup.in_northern_ireland?).to be true
        expect(lookup.in_scotland?).to be false
      end
    end

    context "with a UPRN reference with the UPRN prefix and zero padding" do
      it "gets a lookup that is a match and is in the right country", :aggregate_failures do
        lookup = gateway.lookup_from_uprn "UPRN-000000012345"
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be true
      end
    end

    context "with a UPRN reference that does not exist" do
      it "gets a lookup that is not a match and has no country codes", :aggregate_failures do
        lookup = gateway.lookup_from_uprn "54321"
        expect(lookup.match?).to be false
        expect(lookup.country_codes.empty?).to be true
      end
    end
  end

  context "when looking up country by postcode" do
    before do
      add_address_base uprn: "13579", postcode: "HR3 6HW", country_code: "E"
      add_address_base uprn: "13580", postcode: "HR3 6HW", country_code: "W"
      add_address_base uprn: "86", postcode: "SW1A 1AA", country_code: "E"
    end

    context "with a postcode that only sits in England" do
      it "gets a result that reflects England only", :aggregate_failures do
        lookup = gateway.lookup_from_postcode "SW1A 1AA"
        expect(lookup.match?).to be true
        expect(lookup.in_england?).to be true
        expect(lookup.in_wales?).to be false
      end
    end

    context "with a postcode that sits in England and Wales" do
      it "gets a result that reflects both England and Wales" do
        lookup = gateway.lookup_from_postcode "HR3 6HW"
        expect(lookup.match?).to be true
        expect(lookup.in_england?).to be true
        expect(lookup.in_wales?).to be true
        expect(lookup.in_northern_ireland?).to be false
      end
    end

    context "with a postcode that does not match one in address base" do
      it "gets a result that is not a match" do
        lookup = gateway.lookup_from_postcode "LS1 1AA"
        expect(lookup.match?).to be false
      end
    end
  end

  context "when looking up country with an address base table not populated by country codes" do
    before do
      add_address_base uprn: "13579", postcode: "HR3 6HW", country_code: nil
      add_address_base uprn: "13580", postcode: "HR3 6HW", country_code: nil
    end

    it "gets a result that is not a match" do
      lookup = gateway.lookup_from_postcode "HR3 6HW"
      expect(lookup.match?).to be false
    end
  end
end
