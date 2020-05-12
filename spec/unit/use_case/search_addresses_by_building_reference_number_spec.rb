describe UseCase::SearchAddressesByBuildingReferenceNumber do
  context "addresses without a lodged assessment" do
    let(:gateway) { AddressSearchGatewayFake.new }
    let(:use_case) { described_class.new gateway }

    describe "by RRN" do
      it "does not return any results" do
        results = use_case.execute building_reference_number: "RRN-0000-0000-0000-0000-0000"
        expect(results).to eq []
      end
    end
  end
end
