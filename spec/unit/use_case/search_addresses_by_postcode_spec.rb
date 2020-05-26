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
          assessment_type: "CEPC",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0000", assessment_type: "CEPC"
            },
          ],
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
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0001",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway.add(
        {
          building_reference_number: "RRN-0000-0000-0000-0000-0002",
          line1: "The Name",
          line2: "129 Home Road",
          line3: nil,
          town: "Placeville",
          postcode: "PL4 V12",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0002",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway
    end

    let(:use_case) { described_class.new gateway }

    describe "by postcode" do
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
        expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
        expect(results[0].existing_assessments).to eq [
          assessment_id: "0000-0000-0000-0000-0000", assessment_type: "CEPC",
        ]
      end

      context "with address type" do
        it "returns the domestic address" do
          results =
            use_case.execute postcode: "PL4 V12", address_type: "DOMESTIC"

          expect(results.length).to eq 2
          expect(
            results[0].building_reference_number,
          ).to eq "RRN-0000-0000-0000-0000-0001"
          expect(results[0].line1).to eq "128 Home Road"
          expect(results[0].line2).to be_nil
          expect(results[0].line3).to be_nil
          expect(results[0].town).to eq "Placeville"
          expect(results[0].postcode).to eq "PL4 V12"
          expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
          expect(results[0].existing_assessments).to eq [
            assessment_id: "0000-0000-0000-0000-0001",
            assessment_type: "RdSAP",
          ]
        end

        it "returns the commercial address" do
          results =
            use_case.execute postcode: "PL4 V11", address_type: "COMMERCIAL"

          expect(results.length).to eq 1
          expect(
            results[0].building_reference_number,
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(results[0].line1).to eq "127 Home Road"
          expect(results[0].line2).to be_nil
          expect(results[0].line3).to be_nil
          expect(results[0].town).to eq "Placeville"
          expect(results[0].postcode).to eq "PL4 V11"
          expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
          expect(results[0].existing_assessments).to eq [
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_type: "CEPC",
          ]
        end
      end

      context "with building number on address line two" do
        it "returns the expected address" do
          results =
            use_case.execute postcode: "PL4 V12", building_name_number: "129"

          expect(results.length).to eq 1
          expect(
            results[0].building_reference_number,
          ).to eq "RRN-0000-0000-0000-0000-0002"
          expect(results[0].line1).to eq "The Name"
          expect(results[0].line2).to eq "129 Home Road"
          expect(results[0].line3).to be_nil
          expect(results[0].town).to eq "Placeville"
          expect(results[0].postcode).to eq "PL4 V12"
          expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
          expect(results[0].existing_assessments).to eq [
            assessment_id: "0000-0000-0000-0000-0002",
            assessment_type: "RdSAP",
          ]
        end
      end
    end
  end
end
