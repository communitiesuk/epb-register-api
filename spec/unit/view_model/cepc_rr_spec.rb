require_relative "xml_view_test_helper"

describe ViewModel::CepcRrWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "cepc-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "cepc-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          },
        },
        { schema: "CEPC-7.1", type: "cepc-rr" },
        { schema: "CEPC-7.0", type: "cepc-rr" },
        { schema: "CEPC-6.0", type: "cepc-rr" },
        { schema: "CEPC-5.1", type: "cepc-rr" },
        { schema: "CEPC-5.0", type: "cepc-rr" },
        {
          schema: "CEPC-4.0",
          type: "cepc-rr",
          different_buried_fields: {
            technical_information: {
              building_environment: "Air Conditioning",
            },
          },
        },
        {
          schema: "CEPC-3.1",
          type: "cepc-rr",
          different_buried_fields: {
            technical_information: {
              building_environment: "Air Conditioning",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        report_type: "4",
        type_of_assessment: "CEPC-RR",
        date_of_expiry: "2021-05-03",
        date_of_registration: "2020-05-05",
        address: {
          address_id: "LPRN-000000000000",
          address_line1: "Some Unit",
          address_line2: "2 Lonely Street",
          address_line3: "Some Area",
          address_line4: "Some County",
          town: "Post-Town0",
          postcode: "A0 0AA",
        },
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "Mrs Report Writer",
          company_details: {
            name: "Joe Bloggs Ltd",
            address: "123 My Street, My City, AB3 4CD",
          },
          contact_details: {
            email: "a@b.c",
            telephone: "012345",
          },
        },
        technical_information: {
          floor_area: "10",
          building_environment: "Natural Ventilation Only",
          calculation_tool: "Calculation-Tool0",
        },
        related_party_disclosure: "Related to the owner",
        short_payback_recommendations: [
          {
            code: "ECP-L5",
            text:
              "Consider replacing T8 lamps with retrofit T5 conversion kit.",
            cO2Impact: "HIGH",
          },
          {
            code: "EPC-L7",
            text:
              "Introduce HF (high frequency) ballasts for fluorescent tubes: Reduced number of fittings required.",
            cO2Impact: "LOW",
          },
        ],
        medium_payback_recommendations: [
          {
            code: "EPC-H7",
            text: "Add optimum start/stop to the heating system.",
            cO2Impact: "MEDIUM",
          },
        ],
        long_payback_recommendations: [
          {
            code: "EPC-R5",
            text: "Consider installing an air source heat pump.",
            cO2Impact: "HIGH",
          },
        ],
        other_recommendations: [
          { code: "EPC-R4", text: "Consider installing PV.", cO2Impact: "HIGH" },
        ],
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  context "when calling to_report" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "cepc-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "cepc-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          },
        },
        { schema: "CEPC-7.1", type: "cepc-rr" },
        { schema: "CEPC-7.0", type: "cepc-rr" },
        { schema: "CEPC-6.0", type: "cepc-rr" },
        { schema: "CEPC-5.1", type: "cepc-rr" },
        { schema: "CEPC-5.0", type: "cepc-rr" },
        {
          schema: "CEPC-4.0",
          type: "cepc-rr",
          different_buried_fields: {
            technical_information: {
              building_environment: "Air Conditioning",
            },
          },
        },
        {
          schema: "CEPC-3.1",
          type: "cepc-rr",
          different_buried_fields: {
            technical_information: {
              building_environment: "Air Conditioning",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        rrn: "0000-0000-0000-0000-0000",
        recommendations: [
          {
            payback: "short",
            recommendation_code: "ECP-L5",
            recommendation:
              "Consider replacing T8 lamps with retrofit T5 conversion kit.",
            cO2_Impact: "HIGH",
          },
          {
            payback: "short",
            recommendation_code: "EPC-L7",
            recommendation:
              "Introduce HF (high frequency) ballasts for fluorescent tubes: Reduced number of fittings required.",
            cO2_Impact: "LOW",
          },
          {
            payback: "medium",
            recommendation_code: "EPC-H7",
            recommendation: "Add optimum start/stop to the heating system.",
            cO2_Impact: "MEDIUM",
          },
          {
            payback: "long",
            recommendation_code: "EPC-R5",
            recommendation: "Consider installing an air source heat pump.",
            cO2_Impact: "HIGH",
          },
          {
            payback: "other",
            recommendation_code: "EPC-R4",
            recommendation: "Consider installing PV.",
            cO2_Impact: "HIGH",
          },
        ],
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion, :to_report)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect { ViewModel::CepcRrWrapper.new "", "invalid" }.to raise_error(
      ArgumentError,
    ).with_message "Unsupported schema type"
  end
end
