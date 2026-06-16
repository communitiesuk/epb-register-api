describe UseCase::SearchAddressesByAddressId do
  subject(:use_case) { described_class.new }

  let(:gateway) { instance_double Gateway::AddressSearchGateway }
  let(:result) do
    [Domain::Address.new(
      address_id: "RRN-0000-0000-0000-0000-0044",
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
    allow(gateway).to receive(:search_by_address_id).and_return(result)
  end

  describe "#execute" do
    it "passes the arguments to the gateway" do
      use_case.execute(address_id: "RRN-0000-0000-0000-0000-0044")
      expect(gateway).to have_received(:search_by_address_id).with("RRN-0000-0000-0000-0000-0044").once
    end

    it "return the expected data" do
      expect(use_case.execute(address_id: "RRN-0000-0000-0000-0000-0044")).to eq result
    end
  end
end
