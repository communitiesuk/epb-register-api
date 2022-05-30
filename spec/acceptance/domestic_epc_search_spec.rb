describe "fetching domestic epc search results from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id: scheme_id,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        non_domestic_dec: "ACTIVE",
        non_domestic_nos3: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:feature_flag) do
    "register-api-domestic-epc-search-endpoint-enabled"
  end

  describe "when calling the address search end point" do
    before do
      allow(Helper::Toggles).to receive(:enabled?)
      allow(Helper::Toggles).to receive(:enabled?).with(feature_flag).and_return(true)
    end

    let(:scope) do
      %w[domestic_epc:assessment:search]
    end

    let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

    context "when there are two matching assessments for a search" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      let(:response_body) do
        { assessments: [epcRrn: "0000-0000-0000-0000-0000",
                        address: {
                          addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "A0 0AA", town: "Whitbury"
                        }] }
      end

      it "returns the matching assessment details in the expected format" do
        response = JSON.parse(
          find_domestic_epcs_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
            accepted_responses: [200],
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq response_body
      end
    end

    context "when the postcode provided as part of the address is not valid" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          find_domestic_epcs_by_address(
            postcode: "A0",
            building_name_or_number: "1",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the postcode parameter in the search query was not valid"
      end
    end

    context "when a postcode parameter is provided without a building name or number" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          find_domestic_epcs_by_arbitrary_params(
            params: { postcode: "A0 0AA" },
            accepted_responses: [s],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end

    context "when performing a search with no query parameters" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          find_domestic_epcs_by_arbitrary_params(
            params: {},
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end

    context "when passing the incorrect scopes" do
      it "returns a 403 UNAUTHORISED response" do
        response = JSON.parse(find_domestic_epcs_by_address(
          postcode: "A0 0AA",
          building_name_or_number: "1",
          accepted_responses: [403],
          scopes: %w[wrong:scope],
        ).body,
                              symbolize_names: true)

        expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
      end
    end

    context "when the feature flag for the this endpoint is not enabled" do
      before do
        allow(Helper::Toggles).to receive(:enabled?).with(feature_flag).and_return(false)
      end

      it "receives a 501 with an appropriate error" do
        response = JSON.parse(
          find_domestic_epcs_by_arbitrary_params(
            params: {},
            accepted_responses: [501],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "This endpoint is not implemented"
      end
    end
  end
end
