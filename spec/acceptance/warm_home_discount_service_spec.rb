describe "fetching Warm Home Discount Service details from the API", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:sap_xml) { Samples.xml "SAP-Schema-18.0.0" }

  let(:expected_rdsap_details) do
    {
      "assessment": {
        "address": {
          addressLine1: "1 Some Street",
          addressLine2: "",
          addressLine3: "",
          addressLine4: "",
          town: "Whitbury",
          postcode: "SW1A 2AA",
        },
        "lodgementDate": "2020-05-04",
        "isLatestAssessmentForAddress": true,
        "propertyType": "Mid-terrace house",
        "builtForm": "Semi-Detached",
        "propertyAgeBand": "2007-2011",
        "totalFloorArea": 55,
        "uprn": "000000000000",
      },
    }
  end

  let(:expected_sap_details) do
    {
      "assessment": {
        "address": {
          addressLine1: "1 Some Street",
          addressLine2: "Some Area",
          addressLine3: "Some County",
          addressLine4: "",
          town: "Whitbury",
          postcode: "SW1A 2AA",
        },
        "lodgementDate": "2020-05-04",
        "isLatestAssessmentForAddress": true,
        "propertyType": "Mid-terrace house",
        "builtForm": "Detached",
        "propertyAgeBand": "1750",
        "totalFloorArea": 69,
        "uprn": "000000000000",
      },
    }
  end

  context "when getting Warm Home Discount service details with a RRN" do
    context "when the RRN is associated with an RdSAP assessment that Warm Home Discount service details can be sent for" do
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

      it "returns the matching assessment Warm Home Discount service details in the expected format" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when the address is not a UPRN" do
      before do
        rdsap_xml.gsub!("UPRN-000000000000", "RRN-0000-0000-0000-0000-0000")
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns the matching assessment Warm Home Discount service details in the expected format" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
        expect(response[:data][:assessment][:uprn]).to be_nil
      end
    end

    context "when passing in the includeTypeOfProperty parameter set to true" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
        expected_rdsap_details[:assessment][:typeOfProperty] = "House"
      end

      it "returns the matching assessment Warm Home Discount service details with the additional key typeOfProperty" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn_with_property_type("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when passing in the includeTypeOfProperty parameter set to false" do
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

      it "returns the matching assessment Warm Home Discount service details without the additional key typeOfProperty" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn_with_property_type("0000-0000-0000-0000-0000", param_value: "false").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when the RRN is associated with a SAP assessment that Warm Home Discount service details can be sent for" do
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

      it "returns the matching assessment Warm Home Discount service details in the expected format" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_sap_details
      end
    end

    context "when the RRN provided is valid but that Warm Home Discount service details cannot be returned for" do
      it "returns a 404 response with an expected error message" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn(
            "5555-6666-7777-8888-9999",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the Warm Home Discount service could be found for that query"
      end
    end

    context "when an RRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn(
            "00001111222233334444",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the assessment ID (RRN) in the endpoint URL was not valid"
      end
    end

    context "when a valid RRN is provided but the auth scope is not correct" do
      it "receives a 403 with appropriate error" do
        response = JSON.parse(
          warm_home_discount_details_by_rrn(
            "2222-3333-4444-5555-6666",
            accepted_responses: [403],
            scopes: %w[wrong:scope],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
      end
    end
  end
end
