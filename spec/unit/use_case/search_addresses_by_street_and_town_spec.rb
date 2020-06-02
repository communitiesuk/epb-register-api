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
          address_id: "RRN-0000-0000-0000-0000-0000",
          line1: "127 Home Road",
          line2: nil,
          line3: nil,
          line4: nil,
          town: "Placeville",
          postcode: "PL4 V11",
          assessment_type: "CEPC",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_status: "ENTERED",
              assessment_type: "CEPC",
            },
          ],
        },
      )

      gateway.add(
        {
          address_id: "RRN-0000-0000-0000-0000-0001",
          line1: "128 Home Road",
          line2: nil,
          line3: nil,
          line4: nil,
          town: "Placeville",
          postcode: "PL4 V12",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0001",
              assessment_status: "ENTERED",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway.add(
        {
          address_id: "RRN-0000-0000-0000-0000-0002",
          line1: "The Name",
          line2: "129 Home Road",
          line3: nil,
          line4: nil,
          town: "Placeville",
          postcode: "PL4 V13",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0002",
              assessment_status: "ENTERED",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway.add(
        {
          address_id: "RRN-0000-0000-0000-0000-0003",
          line1: "130 Home Road",
          line2: "Placeville",
          line3: nil,
          line4: nil,
          town: "Countyshire",
          postcode: "PL4 V14",
          assessment_type: "RdSAP",
          source: "PREVIOUS_ASSESSMENT",
          existing_assessments: [
            {
              assessment_id: "0000-0000-0000-0000-0003",
              assessment_status: "ENTERED",
              assessment_type: "RdSAP",
            },
          ],
        },
      )

      gateway
    end
    let(:use_case) { described_class.new gateway }

    describe "by street and town" do
      let(:results) { use_case.execute street: "Home Road", town: "Placeville" }

      it "returns the expected number of results" do
        expect(results.length).to eq 4
      end

      it "returns the expected building reference number" do
        expect(results[0].address_id).to eq "RRN-0000-0000-0000-0000-0000"
      end

      it "returns the expected first line of the address" do
        expect(results[0].line1).to eq "127 Home Road"
      end

      it "returns the expected second line of the address" do
        expect(results[0].line2).to be_nil
      end

      it "returns the expected third line of the address" do
        expect(results[0].line3).to be_nil
      end

      it "returns the expected town" do
        expect(results[0].town).to eq "Placeville"
      end

      it "returns the expected postcode" do
        expect(results[0].postcode).to eq "PL4 V11"
      end

      it "returns the expected address source" do
        expect(results[0].source).to eq "PREVIOUS_ASSESSMENT"
      end

      it "returns the expected list of existing assessments" do
        expect(results[0].existing_assessments.length).to eq 1
      end

      it "returns an existing assessment with the expected RRN" do
        expect(
          results[0].existing_assessments[0][:assessment_id],
        ).to eq "0000-0000-0000-0000-0000"
      end

      it "returns an existing assessment with the expected status" do
        expect(
          results[0].existing_assessments[0][:assessment_status],
        ).to eq "ENTERED"
      end

      it "returns an existing assessment of the expected type" do
        expect(
          results[0].existing_assessments[0][:assessment_type],
        ).to eq "CEPC"
      end

      context "when street is on address line 2" do
        describe "searching for an address" do
          let(:results) do
            use_case.execute street: "Home Road", town: "Placeville"
          end

          it "returns the expected number of results" do
            expect(results.length).to eq 4
          end

          it "returns the expected building reference number" do
            expect(results[2].address_id).to eq "RRN-0000-0000-0000-0000-0002"
          end

          it "returns the expected first line of the address" do
            expect(results[2].line1).to eq "The Name"
          end

          it "returns the expected second line of the address" do
            expect(results[2].line2).to eq "129 Home Road"
          end

          it "returns the expected third line of the address" do
            expect(results[2].line3).to be_nil
          end

          it "returns the expected town" do
            expect(results[2].town).to eq "Placeville"
          end

          it "returns the expected postcode" do
            expect(results[2].postcode).to eq "PL4 V13"
          end

          it "returns the expected address source" do
            expect(results[2].source).to eq "PREVIOUS_ASSESSMENT"
          end

          it "returns the expected list of existing assessments" do
            expect(results[2].existing_assessments.length).to eq 1
          end

          it "returns an existing assessment with the expected RRN" do
            expect(
              results[2].existing_assessments[0][:assessment_id],
            ).to eq "0000-0000-0000-0000-0002"
          end

          it "returns an existing assessment with the expected status" do
            expect(
              results[2].existing_assessments[0][:assessment_status],
            ).to eq "ENTERED"
          end

          it "returns an existing assessment of the expected type" do
            expect(
              results[2].existing_assessments[0][:assessment_type],
            ).to eq "RdSAP"
          end
        end
      end

      context "when town is on address line 2" do
        describe "searching for an address" do
          let(:results) do
            use_case.execute street: "Home Road", town: "Placeville"
          end

          it "returns the expected number of results" do
            expect(results.length).to eq 4
          end

          it "returns the expected building reference number" do
            expect(results[2].address_id).to eq "RRN-0000-0000-0000-0000-0002"
          end

          it "returns the expected first line of the address" do
            expect(results[2].line1).to eq "The Name"
          end

          it "returns the expected second line of the address" do
            expect(results[2].line2).to eq "129 Home Road"
          end

          it "returns the expected third line of the address" do
            expect(results[2].line3).to be_nil
          end

          it "returns an empty fourth line" do
            expect(results[0].line4).to be_nil
          end

          it "returns the expected town" do
            expect(results[2].town).to eq "Placeville"
          end

          it "returns the expected postcode" do
            expect(results[2].postcode).to eq "PL4 V13"
          end

          it "returns the expected address source" do
            expect(results[2].source).to eq "PREVIOUS_ASSESSMENT"
          end

          it "returns the expected list of existing assessments" do
            expect(results[2].existing_assessments.length).to eq 1
          end

          it "returns an existing assessment with the expected RRN" do
            expect(
              results[2].existing_assessments[0][:assessment_id],
            ).to eq "0000-0000-0000-0000-0002"
          end

          it "returns an existing assessment with the expected status" do
            expect(
              results[2].existing_assessments[0][:assessment_status],
            ).to eq "ENTERED"
          end

          it "returns an existing assessment of the expected type" do
            expect(
              results[2].existing_assessments[0][:assessment_type],
            ).to eq "RdSAP"
          end
        end
      end

      context "when address type is provided" do
        describe "searching for domestic addresses" do
          let(:results) do
            use_case.execute street: "Home Road",
                             town: "Placeville",
                             address_type: "DOMESTIC"
          end

          it "returns the expected number of results" do
            expect(results.length).to eq 3
          end

          it "returns a list existing assessments of the expected type" do
            types =
              results.map(&:existing_assessments).map(&:first).map do |ea|
                ea[:assessment_type]
              end
            expect(types).to eq %w[RdSAP RdSAP RdSAP]
          end
        end

        describe "searching for commercial addresses" do
          let(:results) do
            use_case.execute street: "Home Road",
                             town: "Placeville",
                             address_type: "COMMERCIAL"
          end

          it "returns the expected number of results" do
            expect(results.length).to eq 1
          end

          it "returns a list existing assessments of the expected type" do
            types =
              results.map(&:existing_assessments).map(&:first).map do |ea|
                ea[:assessment_type]
              end
            expect(types).to eq %w[CEPC]
          end
        end
      end
    end
  end
end
