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
      "data": {
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
          "lodgementDate": "2020-02-29",
          "isLatestAssessmentForAddress": true,
          "propertyType": "Mid-terrace house",
          "builtForm": "End-Terrace",
          "propertyAgeBand": "D",
          "wallsDescription": [
            "Solid brick, as built, no insulation",
            "Cavity wall, as built, insulated (assumed)",
          ],
          "floorDescription": [
            "Suspended, no insulation (assumed)",
            "Solid, no insulation (assumed)",
          ],
          "roofDescription": [
            "Pitched, 250 mm loft insulation",
            "Pitched, limited insulation (assumed)",
          ],
          "windowsDescription": [
            "Fully double glazed",
          ],
          "mainHeatingDescription": "Boiler and radiators, mains gas",
          "mainFuelType": "Natural Gas",
          "hasHotWaterCylinder": true,
        },
      },
    }
  end

  let(:expected_sap_details) do
    {
      "data": {
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
          "lodgementDate": "2020-02-29",
          "isLatestAssessmentForAddress": true,
          "propertyType": "Mid-terrace house",
          "builtForm": "End-Terrace",
          "propertyAgeBand": "D",
          "wallsDescription": [
            "Solid brick, as built, no insulation",
            "Cavity wall, as built, insulated (assumed)",
          ],
          "floorDescription": [
            "Suspended, no insulation (assumed)",
            "Solid, no insulation (assumed)",
          ],
          "roofDescription": [
            "Pitched, 250 mm loft insulation",
            "Pitched, limited insulation (assumed)",
          ],
          "windowsDescription": [
            "Fully double glazed",
          ],
          "mainHeatingDescription": "Boiler and radiators, mains gas",
          "mainFuelType": "Natural Gas",
          "hasHotWaterCylinder": true,
        },
      },
    }
  end

  context "when getting HERA details with a RRN" do
    context "when the RRN is associated with an assessment that HERA details can be sent for" do
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

      xit "returns the matching assessment HERA details in the expected format" do
        response = JSON.parse(
          hera_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end
  end
end
