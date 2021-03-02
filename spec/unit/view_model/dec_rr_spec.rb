require_relative "xml_view_test_helper"

describe ViewModel::DecRrWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "dec-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        {
          schema: "CEPC-8.0.0",
          type: "dec-rr-large-building",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            technical_information: {
              floor_area: "8000",
            },
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "dec-rr",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        { schema: "CEPC-7.1", type: "dec-rr" },
        {
          schema: "CEPC-7.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-7.0", type: "dec-rr" },
        {
          schema: "CEPC-7.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-6.0", type: "dec-rr" },
        {
          schema: "CEPC-6.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-5.1", type: "dec-rr" },
        {
          schema: "CEPC-5.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-5.0", type: "dec-rr" },
        {
          schema: "CEPC-5.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-4.0", type: "dec-rr" },
        {
          schema: "CEPC-4.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-3.1", type: "dec-rr" },
        {
          schema: "CEPC-3.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        report_type: "2",
        type_of_assessment: "DEC-RR",
        date_of_expiry: "2030-05-03",
        date_of_registration: "2020-05-04",
        address: {
          address_id: "LPRN-000000000001",
          address_line1: "Some Unit",
          address_line2: "2 Lonely Street",
          address_line3: "Some Area",
          address_line4: "Some County",
          town: "Fulchester",
          postcode: "A0 0AA",
        },
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "Mrs Report Writer",
          company_details: {
            name: "Trillian Certificates Plc",
            address: "123 My Street, My City, AB3 4CD",
          },
          contact_details: {
            email: "a@b.c",
            telephone: "0555 497 2848",
          },
        },
        short_payback_recommendations: [
          {
            code: "ECP-L5",
            text:
              "Consider thinking about maybe possibly getting a solar panel but only one.",
            cO2Impact: "MEDIUM",
          },
          {
            code: "EPC-L7",
            text:
              "Consider introducing variable speed drives (VSD) for fans, pumps and compressors.",
            cO2Impact: "LOW",
          },
        ],
        medium_payback_recommendations: [
          {
            code: "ECP-C1",
            text:
              "Engage experts to propose specific measures to reduce hot waterwastage and plan to carry this out.",
            cO2Impact: "LOW",
          },
        ],
        long_payback_recommendations: [
          {
            code: "ECP-F4",
            text: "Consider replacing or improving glazing",
            cO2Impact: "LOW",
          },
        ],
        other_recommendations: [
          { code: "ECP-H2", text: "Add a big wind turbine", cO2Impact: "HIGH" },
        ],
        technical_information: {
          building_environment: "Air Conditioning",
          floor_area: "10",
          occupier: "Primary School",
          property_type: "University campus",
          renewable_sources: "Renewable source",
          discounted_energy: "Special discount",
          date_of_issue: "2020-05-04",
          calculation_tool: "DCLG, ORCalc, v3.6.2",
          inspection_type: "Physical",
        },
        site_service_one: {
          description: "Electricity",
          quantity: "751445",
        },
        site_service_two: {
          description: "Gas",
          quantity: "72956",
        },
        site_service_three: {
          description: "Not used",
          quantity: "0",
        },
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
          type: "dec-rr",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        {
          schema: "CEPC-8.0.0",
          type: "dec-rr-large-building",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            technical_information: {
              floor_area: "8000",
            },
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "dec-rr",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        { schema: "CEPC-7.1", type: "dec-rr" },
        {
          schema: "CEPC-7.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-7.0", type: "dec-rr" },
        {
          schema: "CEPC-7.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-6.0", type: "dec-rr" },
        {
          schema: "CEPC-6.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-5.1", type: "dec-rr" },
        {
          schema: "CEPC-5.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-5.0", type: "dec-rr" },
        {
          schema: "CEPC-5.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-4.0", type: "dec-rr" },
        {
          schema: "CEPC-4.0",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        { schema: "CEPC-3.1", type: "dec-rr" },
        {
          schema: "CEPC-3.1",
          type: "dec-rr-ni",
          different_fields: {
            date_of_expiry: "2027-05-03",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        recommendations: [
          {
            payback_type: "short",
            recommendation_code: "ECP-L5",
            recommendation:
              "Consider thinking about maybe possibly getting a solar panel but only one.",
            cO2_Impact: "MEDIUM",
          },
          {
            recommendation_code: "EPC-L7",
            payback_type: "short",
            recommendation:
              "Consider introducing variable speed drives (VSD) for fans, pumps and compressors.",
            cO2_Impact: "LOW",
          },
          {
            payback_type: "medium",
            recommendation_code: "ECP-C1",
            recommendation:
              "Engage experts to propose specific measures to reduce hot waterwastage and plan to carry this out.",
            cO2_Impact: "LOW",
          },
          {
            payback_type: "long",
            recommendation_code: "ECP-F4",
            recommendation: "Consider replacing or improving glazing",
            cO2_Impact: "LOW",
          },
          {
            payback_type: "other",
            recommendation_code: "ECP-H2",
            recommendation: "Add a big wind turbine",
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
    expect { ViewModel::DecRrWrapper.new "", "invalid" }.to raise_error(
      ArgumentError,
    ).with_message "Unsupported schema type"
  end
end
