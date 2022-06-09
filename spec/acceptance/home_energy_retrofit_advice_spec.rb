describe "fetching HERA (Home Energy Retrofit Advice) details from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id: scheme_id,
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
        "typeOfAssessment": "RdSAP",
        "address": {
          addressLine1: "1 Some Street",
          addressLine2: "",
          addressLine3: "",
          addressLine4: "",
          town: "Whitbury",
          postcode: "A0 0AA",
        },
        "lodgementDate": "2020-05-04",
        "isLatestAssessmentForAddress": true,
        "propertyType": "Mid-terrace house",
        "builtForm": "Semi-Detached",
        "propertyAgeBand": "2007-2011",
        "wallsDescription": [
          "Solid brick, as built, no insulation (assumed)",
          "Cavity wall, as built, insulated (assumed)",
        ],
        "floorDescription": [
          "Suspended, no insulation (assumed)",
          "Solid, insulated (assumed)",
        ],
        "roofDescription": [
          "Pitched, 25 mm loft insulation",
          "Pitched, 250 mm loft insulation",
        ],
        "windowsDescription": [
          "Fully double glazed",
        ],
        "mainHeatingDescription": "boiler with radiators or underfloor heating",
        "mainFuelType": "mains gas (not community)",
        "hasHotWaterCylinder": false,
      },
    }
  end

  let(:expected_sap_details) do
    {
      "assessment": {
        "typeOfAssessment": "SAP",
        "address": {
          addressLine1: "1 Some Street",
          addressLine2: "Some Area",
          addressLine3: "Some County",
          addressLine4: "",
          town: "Whitbury",
          postcode: "A0 0AA",
        },
        "lodgementDate": "2020-05-04",
        "isLatestAssessmentForAddress": true,
        "propertyType": "Mid-terrace house",
        "builtForm": "Detached",
        "propertyAgeBand": "1750",
        "wallsDescription": [
          "Brick walls",
          "Brick walls",
        ],
        "floorDescription": [
          "Tiled floor",
          "Tiled floor",
        ],
        "roofDescription": [
          "Slate roof",
          "slate roof",
        ],
        "windowsDescription": [
          "Glass window",
        ],
        "mainHeatingDescription": "heat pump with warm air distribution",
        "mainFuelType": "Electricity: electricity sold to grid",
        "hasHotWaterCylinder": true,
      },
    }
  end

  context "when getting HERA details with a RRN" do
    context "when the RRN is associated with an RdSAP assessment that HERA details can be sent for" do
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

      it "returns the matching assessment HERA details in the expected format" do
        response = JSON.parse(
          hera_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when the RRN is associated with a SAP assessment that HERA details can be sent for" do
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

      it "returns the matching assessment HERA details in the expected format" do
        response = JSON.parse(
          hera_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_sap_details
      end
    end

    context "when the RRN provided is valid but that HERA details cannot be returned for" do
      it "returns a 404 response with an expected error message" do
        response = JSON.parse(
          hera_details_by_rrn(
            "5555-6666-7777-8888-9999",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the Home Energy Retrofit Advice scheme could be found for that query"
      end
    end

    context "when an RRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          hera_details_by_rrn(
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
          hera_details_by_rrn(
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
