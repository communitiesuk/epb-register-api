require_relative "xml_view_test_helper"

describe ViewModel::AcCertWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "ac-cert",
          different_buried_fields: {
            address: {
              address_id: "UPRN-432167890000",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "ac-cert",
          different_buried_fields: {
            address: {
              address_id: "UPRN-432167890000",
            },
          },
        },
        { schema: "CEPC-7.1", type: "ac-cert" },
        { schema: "CEPC-7.0", type: "ac-cert" },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        report_type: "6",
        type_of_assessment: "AC-CERT",
        date_of_expiry: "2024-05-04",
        date_of_registration: "2020-05-20",
        address: {
          address_id: "LPRN-432167890000",
          address_line1: "Some Unit",
          address_line2: "2 Lonely Street",
          address_line3: "Some Area",
          address_line4: "Some County",
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
        technical_information: {
          date_of_assessment: "2020-05-20",
          building_complexity: "Level 3",
          calculation_tool: "Sterling Accreditation, Sterling e-Volve, v1.2",
          f_gas_compliant_date: "00/00/,,00",
          ac_rated_output: "40",
          random_sampling: "Y",
          treated_floor_area: "1876",
          ac_system_metered: "0",
          refrigerant_charge: "50",
        },
        subsystems: [
          {
            number: "VOL001/SYS001 R410A Inverter Split Systems to Sales Area",
            description:
              "This sub system comprised of; 4Nr 10kW R410A Mitsubishi Heavy Industries inverter driven split AC condensers interconnected to indoor cassette units within the Sales Area dating from circa 2014.",
            age: "2014",
            refrigerantType: "R410A",
          },
        ],
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "Test Assessor Name",
          contact_details: {
            email: "test@example.com",
            telephone: "07555 666777",
          },
          company_details: {
            name: "Assess Energy Limited",
            address: "111 Twotwotwo Street, Mytown,, MT7 1AA",
          },
        },
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::AcCertWrapper.new "", "invalid"
    }.to raise_error(ArgumentError)
           .with_message "Unsupported schema type"
  end
end
