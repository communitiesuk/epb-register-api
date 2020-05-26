describe UseCase::SearchAddressesByStreetAndTown do
  context "addresses without a lodged assessment" do
    let(:use_case) { described_class.new AddressSearchGatewayFake.new }

    describe "by postcode" do
      it "does not return any results" do
        results = use_case.execute street: "Fake Street", town: "Ghost"

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
          postcode: "PL4 V13",
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

      gateway.add(
        {
          building_reference_number: "RRN-0000-0000-0000-0000-0003",
          line1: "130 Home Road",
          line2: "Placeville",
          line3: nil,
          town: "Countyshire",
          postcode: "PL4 V14",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0003",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway
    end
    let(:use_case) { described_class.new gateway }

    describe "by street and town" do
      it "returns the expected address" do
        results = use_case.execute street: "Home Road", town: "Placeville"

        expect(results.length).to eq 4
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

      context "when street is on address line 2" do
        it "returns the expected address" do
          results = use_case.execute street: "Home Road", town: "Placeville"

          expect(results.length).to eq 4
          expect(
            results[2].building_reference_number,
          ).to eq "RRN-0000-0000-0000-0000-0002"
          expect(results[2].line1).to eq "The Name"
          expect(results[2].line2).to eq "129 Home Road"
          expect(results[2].line3).to be_nil
          expect(results[2].town).to eq "Placeville"
          expect(results[2].postcode).to eq "PL4 V13"
          expect(results[2].source).to eq "PREVIOUS_ASSESSMENT"
          expect(results[2].existing_assessments).to eq [
            assessment_id: "0000-0000-0000-0000-0002",
            assessment_type: "RdSAP",
          ]
        end
      end

      context "when town is on address line 2" do
        it "returns the expected address" do
          results = use_case.execute street: "Home Road", town: "Placeville"

          expect(results.length).to eq 4
          expect(
            results[3].building_reference_number,
          ).to eq "RRN-0000-0000-0000-0000-0003"
          expect(results[3].line1).to eq "130 Home Road"
          expect(results[3].line2).to eq "Placeville"
          expect(results[3].line3).to be_nil
          expect(results[3].town).to eq "Countyshire"
          expect(results[3].postcode).to eq "PL4 V14"
          expect(results[3].source).to eq "PREVIOUS_ASSESSMENT"
          expect(results[3].existing_assessments).to eq [
            assessment_id: "0000-0000-0000-0000-0003",
            assessment_type: "RdSAP",
          ]
        end
      end
    end
  end
end
