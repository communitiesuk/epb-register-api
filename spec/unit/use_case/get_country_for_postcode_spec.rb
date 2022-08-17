describe UseCase::GetCountryForPostcode do
  subject(:use_case) { described_class.new address_base_country_gateway: }

  let(:address_base_country_gateway) do
    gateway = instance_double Gateway::AddressBaseCountryGateway
    allow(gateway).to receive :lookup_from_postcode
    gateway
  end

  context "when the postcode given is definitely within wales only" do
    let(:postcode) { "CF10 1EP" }

    it "returns a lookup that matches only wales", aggregate_failures: true do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be true
      expect(lookup.in_england?).to be false
    end
  end

  context "when the postcode given has an outcode that marks it as being in wales only" do
    let(:postcode) { "LL24 4EF" }

    it "returns a lookup that matches only wales without calling the gateway", aggregate_failures: true do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is in northern ireland" do
    let(:postcode) { "BT1 1AA" }

    it "returns a lookup that matches only northern ireland without calling the gateway" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_northern_ireland?).to be true
      expect(lookup.in_england?).to be false
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is definitely only in england" do
    let(:postcode) { "SL4 1EQ" }

    it "returns a lookup that matches only england" do
      lookup = use_case.execute(postcode:)
      expect(lookup.match?).to be true
      expect(lookup.in_wales?).to be false
      expect(lookup.in_england?).to be true
      expect(address_base_country_gateway).not_to have_received :lookup_from_postcode
    end
  end

  context "when the postcode given is in a cross-border area, a lookup is performed on the gateway" do
    context "with the gateway returning a location in england only" do
      let(:postcode) { "HR2 0PP" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: [:E]))
      end

      it "returns a lookup that matches only england" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be false
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end

    context "with the gateway returning a location in both england and wales" do
      let(:postcode) { "HR2 8RA" }

      before do
        allow(address_base_country_gateway).to receive(:lookup_from_postcode).and_return(Domain::CountryLookup.new(country_codes: %i[E W]))
      end

      it "returns a lookup that matches england and wales" do
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

      it "returns a lookup that matches both england and wales" do
        lookup = use_case.execute(postcode:)
        expect(lookup.match?).to be true
        expect(lookup.in_wales?).to be true
        expect(lookup.in_england?).to be true
        expect(address_base_country_gateway).to have_received :lookup_from_postcode
      end
    end
  end
end
