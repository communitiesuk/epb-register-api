require_relative "xml_view_test_helper"

expected_summary = %Q(The objective and intention of the inspection and this report is to provide the client/end user with information relating to the installed Air Conditioning/Comfort Cooling systems (AC) and Ventilation Systems and endeavour to provide ideas and recommendations for the site to reduce its CO2 emissions, lower energy consumption and save money on energy bills.

        BUILDING TYPE/DETAILS:

        The site inspected was; A Shop located in London. The site was inspected on the 20th May 2019. The estimated total floor area provided with air conditioning/comfort cooling (AC) on site was circa; 1876m2.

      )

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
        xml: Samples.xml("CEPC-7.1", "ac-report"),
        unsupported_fields: [],
        different_fields: {},
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
      executive_summary: expected_summary
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
