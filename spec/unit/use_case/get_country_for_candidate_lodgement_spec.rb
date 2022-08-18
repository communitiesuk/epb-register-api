describe UseCase::GetCountryForCandidateLodgement do
  subject(:use_case) do
    described_class.new get_canonical_address_id_use_case:,
                        get_country_for_postcode_use_case:,
                        address_base_country_gateway:
  end

  let(:get_canonical_address_id_use_case) { instance_double UseCase::GetCanonicalAddressId }
  let(:get_country_for_postcode_use_case) { instance_double UseCase::GetCountryForPostcode }
  let(:address_base_country_gateway) { instance_double Gateway::AddressBaseCountryGateway }

  context "when the canonical address ID is not a UPRN that exists" do
    let(:nonexistent_uprn) { "UPRN-000000000002" }
    let(:postcode) { "SL4 1QN" }

    let(:params) do
      {
        rrn: "1234-5678-1234-1234-5678",
        address_id: nonexistent_uprn,
        postcode:,
      }
    end

    before do
      allow(get_canonical_address_id_use_case).to receive(:execute).with(include(address_id: nonexistent_uprn)).and_return "RRN-1234-5678-1234-1234-5678"
      allow(get_country_for_postcode_use_case).to receive(:execute).with(postcode:).and_return(Domain::CountryLookup.new(country_codes: %i[N W]))
    end

    it "gets the lookup from the postcode use case" do
      lookup = use_case.execute(**params)
      expect(lookup.country_codes).to eq %i[N W]
      expect(get_country_for_postcode_use_case).to have_received(:execute)
    end
  end

  context "when the canonical address ID is a UPRN that exists" do
    let(:existent_uprn) { "UPRN-123456789012" }
    let(:postcode) { "SE23 3RT" }

    let(:params) do
      {
        rrn: "3456-3456-3445-4556-5567",
        address_id: existent_uprn,
        postcode:,
      }
    end

    before do
      allow(get_canonical_address_id_use_case).to receive(:execute).with(include(address_id: existent_uprn)).and_return existent_uprn
      allow(address_base_country_gateway).to receive(:lookup_from_uprn).with(existent_uprn).and_return(Domain::CountryLookup.new(country_codes: [:E]))
    end

    it "gets the lookup from the gateway using the UPRN" do
      lookup = use_case.execute(**params)
      expect(lookup.country_codes).to eq %i[E]
      expect(address_base_country_gateway).to have_received(:lookup_from_uprn)
    end
  end
end
