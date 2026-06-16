describe UseCase::SearchAddressesByPostcode do
  subject(:use_case) { described_class.new }

  let(:gateway) { instance_double Gateway::AddressSearchGateway }
  let(:result) do
    [Domain::Address.new(
      address_id: "UPRN-000000000001",
      line1: "1",
      line2: "SOME UNIT",
      line3: "",
      line4: "",
      town: "LONDON",
      postcode: "SW1A 2AA",
      country: %w[E],
      source: "GAZETTEER",
      existing_assessments: nil,
    )]
  end

  before do
    allow(Gateway::AddressSearchGateway).to receive(:new).and_return(gateway)
    allow(gateway).to receive(:search_by_postcode).and_return(result)
  end

  describe "#execute" do
    it "passes the arguments to the gateway" do
      use_case.execute(postcode: "SW1A 2AA", building_name_number: "1", address_type: "COMMERCIAL")
      expect(gateway).to have_received(:search_by_postcode).with("SW1A 2AA", "1", "COMMERCIAL").once
    end

    it "return the expected data" do
      expect(use_case.execute(postcode: "SW1A 2AA", building_name_number: "1", address_type: "COMMERCIAL")).to eq result
    end
  end

  context "when arguments include non token characters" do
    context "when searching with a buildingNameNumber string prefixed by a valid, existing street number" do
      it "strips the certain character from the building number" do
        use_case.execute(postcode: "SW1A 2AA", building_name_number: "1():*!&\\")
        expect(gateway).to have_received(:search_by_postcode).with("SW1A 2AA", "1&", nil).once
      end
    end
  end
end
