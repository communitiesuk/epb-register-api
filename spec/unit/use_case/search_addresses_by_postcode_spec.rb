describe UseCase::SearchAddressesByPostcode do
  context "addresses without a lodged assessment" do
    let(:use_case) { described_class.new AddressSearchGatewayFake.new }

    describe "by postcode" do
      it "does not return any results" do
        results = use_case.execute postcode: "S8 0NX"

        expect(results).to eq []
      end
    end
  end

  context "addresses with a lodged assessment" do
    let(:gateway) do
      gateway = AddressSearchGatewayFake.new

      gateway.add(
        {
          building_reference_number: "RRN-0000-0000-0000-0000-0000",
          line1: "127 Home Road",
          line2: nil,
          line3: nil,
          town: "Placeville",
          postcode: "PL4 V11",
        },
      )

      gateway.add(
        {
          building_reference_number: "RRN-0000-0000-0000-0000-0001",
          line1: "128 Home Road",
          line2: nil,
          line3: nil,
          town: "Placeville",
          postcode: "PL4 V12",
        },
      )

      gateway
    end
    let(:use_case) { described_class.new gateway }

    describe "by RRN" do
      it "returns the expected address" do
        results = use_case.execute postcode: "PL4 V11"

        expect(results.length).to eq 1
        expect(
          results[0].building_reference_number,
        ).to eq "RRN-0000-0000-0000-0000-0000"
        expect(results[0].line1).to eq "127 Home Road"
        expect(results[0].line2).to be_nil
        expect(results[0].line3).to be_nil
        expect(results[0].town).to eq "Placeville"
        expect(results[0].postcode).to eq "PL4 V11"
      end
    end
  end
end
