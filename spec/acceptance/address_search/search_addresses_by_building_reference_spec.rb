describe "Acceptance::AddressSearch::ByBuildingReference" do
  include RSpecAssessorServiceMixin

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticRdSap: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  context "when an address that has a report lodged" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:response) do
      JSON.parse(
        assertive_get(
          "/api/search/addresses?buildingReferenceNumber=RRN-0000-0000-0000-0000-0000",
          [200],
          true,
          {},
          %w[address:search],
        )
          .body,
        symbolize_names: true,
      )
    end

    before(:each) do
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by buildingReferenceNumber" do
      it "returns the expected amount of addresses" do
        expect(response[:data][:addresses].length).to eq 1
      end

      it "returns the address" do
        expect(response[:data][:addresses][0]).to eq(
          {
            buildingReferenceNumber: "RRN-0000-0000-0000-0000-0000",
            line1: "1 Some Street",
            line2: nil,
            line3: nil,
            town: "Post-Town1",
            postcode: "A0 0AA",
            source: "PREVIOUS_ASSESSMENT",
            existingAssessments: [
              {
                assessmentId: "0000-0000-0000-0000-0000",
                assessmentStatus: "EXPIRED",
                assessmentType: "RdSAP",
              },
            ],
          },
        )
      end

      context "with an entered assessment" do
        let(:entered_assessment) { Nokogiri.XML valid_rdsap_xml }

        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?buildingReferenceNumber=RRN-0000-0000-0000-0000-0001",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
            symbolize_names: true,
          )
        end

        before do
          assessment_id = entered_assessment.at("RRN")
          assessment_id.children = "0000-0000-0000-0000-0001"

          assessment_date = entered_assessment.at("Inspection-Date")
          assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

          lodge_assessment(
            assessment_body: entered_assessment.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 1
        end

        it "returns the expected address" do
          expect(response[:data][:addresses][0]).to eq(
            {
              buildingReferenceNumber: "RRN-0000-0000-0000-0000-0001",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0001",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end
    end
  end

  context "with a valid combination of parameters that have no matches" do
    describe "with an valid, not in use buildingReferenceNumber" do
      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?buildingReferenceNumber=RRN-1111-2222-3333-4444-5555",
            [200],
            true,
            nil,
            %w[address:search],
          )
            .body,
          symbolize_names: true,
        )
      end

      it "returns an empty result set" do
        expect(response[:data][:addresses].length).to eq 0
      end
    end
  end

  context "with an invalid combination of parameters" do
    describe "with an invalid buildingReferenceNumber" do
      let(:response) do
        assertive_get(
          "/api/search/addresses?buildingReferenceNumber=DOESNOTEXIST",
          [422],
          true,
          nil,
          %w[address:search],
        )
          .body
      end

      it "returns a validation error" do
        expect(response).to include "INVALID_REQUEST"
      end
    end
  end
end
