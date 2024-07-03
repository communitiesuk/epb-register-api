describe UseCase::GetCountryForPostcode do
  subject(:use_case) { described_class.new address_base_country_gateway: }

  let(:address_base_country_gateway) do
    gateway = instance_double Gateway::AddressBaseCountryGateway
    allow(gateway).to receive :lookup_from_postcode
    gateway
  end

  context "when the postcode given is definitely within Wales only" do
    let(:postcode) { "CF10 1EP" }

    it "returns a lookup that matches only Wales", :aggregate_failures do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be true
      expect(lookup.in_england?).to be false
    end
  end

  context "when the postcode given has an outcode that marks it as being in Wales only" do
    let(:postcode) { "LL24 4EF" }

    it "returns a lookup that matches only Wales without calling the gateway", :aggregate_failures do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is in Northern Ireland" do
    let(:postcode) { "BT1 1AA" }

    it "returns a lookup that matches only Northern Ireland without calling the gateway" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_northern_ireland?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is definitely only in England" do
    let(:postcode) { "SL4 1EQ" }

    it "returns a lookup that matches only England" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be false
      expect(lookup.in_england?).to be true
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode is in CH66" do
    let(:postcode) { "CH66 4RT" }

    it "recognises that the postcode is in England, rather than Wales (i.e. not CH6)" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be false
      expect(lookup.in_england?).to be true
    end
  end

  context "when an English postcode ends with SA" do
    let(:postcode) { "PR25 2SA" }

    it "recognises that the postcode is in England, rather than Wales (i.e. does not match SA postal district)" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be false
      expect(lookup.in_england?).to be true
    end
  end

  context "when a Welsh postcode starts with a Wales only postcode prefix" do
    let(:postcode) { "LL31 4RF" }

    it "recognised that the postcode is in Wales and not England" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be true
      expect(lookup.in_england?).to be false
    end
  end

  context "when the postcode given is in a cross English-Welsh border area, a lookup is performed on the gateway" do
    context "with the gateway returning a location in England only" do
      let(:postcode) { "HR2 0PP" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: [:E]))
      end

      it "returns a lookup that matches only England" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be false
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a location in both England and Wales" do
      let(:postcode) { "HR2 8RA" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: %i[E W]))
      end

      it "returns a lookup that matches England and Wales" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be true
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a lookup that does not provide a match" do
      let(:postcode) { "HR2 0ZZ" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: []))
      end

      it "returns a lookup that matches both England and Wales" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be true
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end
  end

  context "when the postcode starts with a Scotland only prefix" do
    let(:postcode) { "IV63 6TU" }

    it "returns a lookup that matches only Scotland without calling the gateway", :aggregate_failures do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_scotland?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given has an outcode that marks it as being in Scotland only" do
    let(:postcode) { "TD14 5TY" }

    it "returns a lookup that matches only Scotland without calling the gateway", :aggregate_failures do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_scotland?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is in a cross English-Scottish border area, a lookup is performed on the gateway" do
    context "with the gateway returning a location in England only" do
      let(:postcode) { "DG16 5HZ" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: [:E]))
      end

      it "returns a lookup that matches only England" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_scotland?).to be false
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a location in Scotland only" do
      let(:postcode) { "DG16 5EA" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: [:S]))
      end

      it "returns a lookup that matches only Scotland" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_scotland?).to be true
        expect(lookup.in_england?).to be false
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a location in both England and Scotland" do
      let(:postcode) { "TD15 1UZ" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: %i[E S]))
      end

      it "returns a lookup that matches England and Scotland" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_england?).to be true
        expect(lookup.in_scotland?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a lookup that does not provide a match" do
      let(:postcode) { "TD15 5HS" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: []))
      end

      it "returns a lookup that matches both England and Scotland" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_scotland?).to be true
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the postcode is in Glasgow" do
      let(:postcode) { "G1 1HD" }

      it "returns a lookup that matches Scotland" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_scotland?).to be true
        expect(lookup.in_england?).to be false
        expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
      end
    end

    context "with the postcode is in Gloucester" do
      let(:postcode) { "GL1 2EH" }

      it "returns a lookup that matches England" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_scotland?).to be false
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
      end
    end
  end
end
