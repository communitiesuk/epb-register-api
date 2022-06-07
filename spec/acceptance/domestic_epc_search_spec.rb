describe "fetching domestic epc search results from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:feature_flag) do
    "register-api-domestic-epc-search-endpoint-enabled"
  end

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  describe "when calling the address search end point" do
    before do
      allow(Helper::Toggles).to receive(:enabled?)
      allow(Helper::Toggles).to receive(:enabled?).with(feature_flag).and_return(true)
    end

    let(:scope) do
      %w[assessment:domestic-epc:search]
    end

    context "when performing a search with a postcode and buildingNameNumber" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected_results) do
        { assessments: [{ address: { addressLine1: "1 Some Street",
                                     addressLine2: "",
                                     addressLine3: "",
                                     addressLine4: "",
                                     postcode: "A0 0AA",
                                     town: "Whitbury" },
                          epcRrn: "0000-0000-0000-0000-0000" }] }
      end

      before do
        add_super_assessor(scheme_id: scheme_id)
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      end

      it "returns the assessment by search using a postcode and exact building number" do
        response = JSON.parse(find_domestic_epcs_with_params(
          params: { postcode: "A0 0AA",
                    buildingNameOrNumber: "1" },
          accepted_responses: [200],
        ).body,
                              symbolize_names: true)

        expect(response[:data]).to eq expected_results
      end

      it "returns the assessment by search using a postcode and building name" do
        response = JSON.parse(find_domestic_epcs_with_params(
          params: { postcode: "A0 0AA",
                    buildingNameOrNumber: "1 Some"  },
          accepted_responses: [200],
        ).body,
                              symbolize_names: true)

        expect(response[:data]).to eq expected_results
      end
    end

    context "when performing a search with a postcode only" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:expected_results) do
        { assessments: [{ address: { addressLine1: "1 Some Street",
                                     addressLine2: "",
                                     addressLine3: "",
                                     addressLine4: "",
                                     postcode: "A0 0AA",
                                     town: "Whitbury" },
                          epcRrn: "0000-0000-0000-0000-0000" }] }
      end

      before do
        add_super_assessor(scheme_id: scheme_id)
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      end

      it "returns the assessment by search using a postcode only" do
        response = JSON.parse(find_domestic_epcs_with_params(
          params: { postcode: "A0 0AA" },
          accepted_responses: [200],
        ).body,
                              symbolize_names: true)

        expect(response[:data]).to eq expected_results
      end
    end

    context "when performing a search with no query parameters" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          find_domestic_epcs_with_params(
            params: {},
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end

    context "when performing a search that does not match any domestic EPCs" do
      it "returns a 404 with an appropriate response" do
        response = JSON.parse(
          find_domestic_epcs_with_params(
            params: {
              postcode: "AB1 2CD",
              building_name_or_number: "42",
            },
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No domestic assessments could be found for that query"
      end
    end

    context "when passing the incorrect scopes" do
      it "returns a 403 UNAUTHORISED response" do
        response = JSON.parse(find_domestic_epcs_with_params(
          params: { postcode: "A0 0AA",
                    buildingNameOrNumber: "1 Some"  },
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
          find_domestic_epcs_with_params(
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
