describe "fetching BUS (Boiler Upgrade Scheme) details from the API", set_with_timecop: true do
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

  let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:sap_xml) { Samples.xml "SAP-Schema-18.0.0" }
  let(:cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }

  let(:expected_rdsap_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "RdSAP",
      expiryDate: "2030-05-03",
      cavityWallInsulationRecommended: false,
      loftInsulationRecommended: false,
      secondaryHeating: "Room heaters, electric",
      address: {
        addressId: "UPRN-000000000000",
        addressLine1: "1 Some Street",
        addressLine2: "",
        addressLine3: "",
        addressLine4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "Mid-terrace house",
    }
  end

  let(:expected_sap_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "SAP",
      expiryDate: "2030-05-03",
      cavityWallInsulationRecommended: false,
      loftInsulationRecommended: false,
      secondaryHeating: "Electric heater",
      address: {
        addressId: "UPRN-000000000000",
        addressLine1: "1 Some Street",
        addressLine2: "Some Area",
        addressLine3: "Some County",
        addressLine4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "Mid-terrace house",
    }
  end

  let(:expected_cepc_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "CEPC",
      expiryDate: "2026-05-04",
      cavityWallInsulationRecommended: nil,
      loftInsulationRecommended: nil,
      secondaryHeating: nil,
      address: {
        addressId: "UPRN-000000000001",
        addressLine1: "Some Unit",
        addressLine2: "2 Lonely Street",
        addressLine3: "Some Area",
        addressLine4: "Some County",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "B1 Offices and Workshop businesses",
    }
  end

  before do
    allow(Helper::Toggles).to receive(:enabled?)
    allow(Helper::Toggles).to receive(:enabled?).with("bus-endpoint-enabled").and_return(true)
  end

  context "when getting BUS details with a RRN" do
    context "when the RRN is associated with an assessment that BUS details can be sent for" do
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

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end
  end

  context "when getting BUS details with a UPRN" do
    context "when the UPRN is associated with assessment details that can be returned for the BUS" do
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

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_uprn("UPRN-000000000000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end
  end

  context "when getting BUS details with a postcode and building name or number" do
    context "when there is one matching assessment to send BUS details for" do
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

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when there are two matching assessments to send BUS details for" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )

        xml = Nokogiri.XML rdsap_xml.dup

        xml.at("RRN").content = "0000-1111-2222-3333-4444"
        xml.at("UPRN").content = "UPRN-000222444666"

        lodge_assessment(
          assessment_body: xml.to_s,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns a list of assessment references with a 300 status code" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
            accepted_responses: [300],
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq({
          links: {
            assessments: %w[0000-0000-0000-0000-0000 0000-1111-2222-3333-4444],
          },
        })
      end
    end

    context "when there are no matching assessments to send BUS details for" do
      it "receives an error response with a 404" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when the postcode provided as part of the address is not valid" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_address(
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
          bus_details_by_arbitrary_params(
            params: { postcode: "A0 0AA" },
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end
  end

  context "when performing a search using an RRN" do
    context "when an RRN is provided in a correct format that matches assessment BUS details that can be sent" do
      before do
        lodge_assessment(
          assessment_body: cepc_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "receives a 200 with the assessment BUS details" do
        response = JSON.parse(
          bus_details_by_rrn(
            "0000-0000-0000-0000-0000",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_cepc_details
      end
    end

    context "when an RRN is provided in a correct format, but does not match existing assessments for BUS" do
      it "receives a 404 with an appropriate error" do
        response = JSON.parse(
          bus_details_by_rrn(
            "0000-1111-2222-3333-4444",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when an RRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_rrn(
            "00001111222233334444",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the rrn parameter in the search query was not valid"
      end
    end
  end

  context "when performing a search using a UPRN" do
    context "when a UPRN is provided in a valid format and pertains to existing assessments" do
      before do
        lodge_assessment(
          assessment_body: sap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
        )
      end

      it "returns a 200 with the expected BUS details" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_sap_details
      end
    end

    context "when a UPRN is provided in a valid format but does not pertain to an existing assessment BUS details can be sent for" do
      it "received an appropriate error with a 404" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-123456789012",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when a UPRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-123456789",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the uprn parameter in the search query was not valid"
      end
    end

    context "when an RRN based address ID is provided for the UPRN field" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_uprn(
            "RRN-0000-1111-2222-3333-4444",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the uprn parameter in the search query was not valid"
      end
    end

    context "when a UPRN is provided but the auth scope is not correct" do
      it "receives a 403 with appropriate error" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
            accepted_responses: [403],
            scopes: %w[wrong:scope],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
      end
    end
  end

  context "when performing a search with no query parameters" do
    it "receives an appropriate error with a 400" do
      response = JSON.parse(
        bus_details_by_arbitrary_params(
          params: {},
          accepted_responses: [400],
        ).body,
        symbolize_names: true,
      )

      expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
    end
  end

  context "when the feature flag for the BUS endpoint is not enabled" do
    before do
      allow(Helper::Toggles).to receive(:enabled?).with("bus-endpoint-enabled").and_return(false)
    end

    it "receives a 501 with an appropriate error" do
      response = JSON.parse(
        bus_details_by_arbitrary_params(
          params: {},
          accepted_responses: [501],
        ).body,
        symbolize_names: true,
      )

      expect(response[:errors][0][:title]).to eq "This endpoint is not implemented"
    end
  end
end
