describe "searching for an address by building reference" do
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

  context "an address that has a report lodged" do
    before(:each) do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by postcode" do
      it "returns the address" do
        response =
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=A0%200AA",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
          )

        expect(response["data"]["addresses"].length).to eq 1
        expect(
          response["data"]["addresses"][0]["buildingReferenceNumber"],
        ).to eq "RRN-0000-0000-0000-0000-0000"
        expect(response["data"]["addresses"][0]["line1"]).to eq "1 Some Street"
        expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
        expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
      end

      context "when there is no space in the postcode" do
        it "returns the address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A00AA",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(response["data"]["addresses"][0]["line1"]).to eq "1 Some Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
        end
      end
    end
  end
end
