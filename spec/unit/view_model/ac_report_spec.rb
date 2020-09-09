require_relative "xml_view_test_helper"

expected_summary =
  'The objective and intention of the inspection and this report is to provide the client/end user with information relating to the installed Air Conditioning/Comfort Cooling systems (AC) and Ventilation Systems and endeavour to provide ideas and recommendations for the site to reduce its CO2 emissions, lower energy consumption and save money on energy bills.

        BUILDING TYPE/DETAILS:

        The site inspected was; A Shop located in London. The site was inspected on the 20th May 2019. The estimated total floor area provided with air conditioning/comfort cooling (AC) on site was circa; 1876m2.

      '

describe ViewModel::AcReportWrapper do
  context "Testing the AC-REPORT schemas" do
    supported_schema = [
      {
        schema_name: "CEPC-8.0.0",
        xml: Samples.xml("CEPC-8.0.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-NI-8.0.0",
        xml: Samples.xml("CEPC-NI-8.0.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.1",
        xml: Samples.xml("CEPC-7.1", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-7.0",
        xml: Samples.xml("CEPC-7.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
      },
      {
        schema_name: "CEPC-6.0",
        xml: Samples.xml("CEPC-6.0", "ac-report"),
        unsupported_fields: [],
        different_fields: {
          related_party_disclosure: "No related Party",
          sub_systems: [],
          pre_inspection_checklist: {},
          related_party_disclosure: "No related Party",
          sub_systems: [],
          cooling_plants: [],
        },
      },
    ].freeze

    asserted_keys = {
      assessment_id: "0000-0000-0000-0000-0000",
      report_type: "5",
      type_of_assessment: "AC-REPORT",
      date_of_expiry: "2030-05-04",
      address: {
        address_line1: "2 Lonely Street",
        address_line2: nil,
        address_line3: nil,
        address_line4: nil,
        town: "Post-Town1",
        postcode: "A0 0AA",
      },
      related_party_disclosure: "1",
      assessor: {
        scheme_assessor_id: "SPEC000000",
        name: "Test Assessor Name",
        contact_details: {
          email: "test@example.com", telephone: "07555 666777"
        },
        company_details: {
          name: "Assess Energy Limited",
          address: "111 Twotwotwo Street, Mytown,, MT7 1AA",
        },
      },
      executive_summary: expected_summary,
      equipment_owner: {
        name: "Manager",
        telephone: "012345",
        organisation: "Shop Ltd",
        address: {
          address_line1: "Shop Ltd",
          address_line2: "PO BOX 123",
          address_line3: nil,
          address_line4: nil,
          town: "Cardiff",
          postcode: "CF15 1FD",
        },
      },
      equipment_operator: {
        responsible_person: "Chief engineer",
        telephone: "44321",
        organisation: "Air Con Ltd",
        address: {
          address_line1: "12 Commercial St",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Coventry",
          postcode: "CV12 3FG",
        },
      },
      key_recommendations: {
        efficiency: [
          { sequence: "0", text: "A way to improve your efficiency" },
          { sequence: "1", text: "A second way to improve efficiency" },
        ],
        maintenance: [{ sequence: "0", text: "Text2" }],
        control: [{ sequence: "0", text: "Text4" }],
        management: [{ sequence: "0", text: "Text6" }],
      },
      sub_systems: [
        volume_definitions: "VOL001 The Shop",
        id: "VOL001/SYS001 R410A Inverter Split Systems to Sales Area",
        description:
          "This sub system comprised of; 4Nr 10kW R410A Mitsubishi Heavy Industries inverter driven split AC condensers.",
        cooling_output: "40",
        area_served: "Sales Area",
        inspection_date: "2019-05-20",
        cooling_plant_count: "4",
        ahu_count: "0",
        terminal_units_count: "4",
        controls_count: "5",
      ],
      pre_inspection_checklist: {
          essential: {control_zones: false, cooling_capacities: false, list_of_systems: true, operation_controls: false, schematics: false, temperature_controls: false},
          desirable: {commissioning_results: false, consumption_records: false, control_system_maintenance: false, delivery_system_maintenance: false, previous_reports: false, refrigeration_maintenance: false},
          optional: {bms_capability: false, complaint_records: false, cooling_load_estimate: false, monitoring_capability: false},
      },
      cooling_plants: [
        {
          system_number: "",
          identifier: "",
          equipment: {},
          inspection: {},
          sizing: {},
          refrigeration: {},
          maintenance: {},
          metering: {},
          humidity_control: {},
        },
        {
          system_number: "",
          identifier: "",
          equipment: {},
          inspection: {},
          sizing: {},
          refrigeration: {},
          maintenance: {},
          metering: {},
          humidity_control: {},
        },
      ],
    }.freeze

    it "should read the appropriate values from the XML doc" do
      test_xml_doc(supported_schema, asserted_keys)
    end

    it "returns the expect error without a valid schema type" do
      expect {
        ViewModel::AcReportWrapper.new "", "invalid"
      }.to raise_error.with_message "Unsupported schema type"
    end
  end
end
