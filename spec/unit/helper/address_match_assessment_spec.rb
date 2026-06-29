describe Helper::AddressMatchAssessment do
  let(:helper) { described_class }

  include RSpecRegisterApiServiceMixin

  before(:all) do
    Timecop.freeze(2023, 6, 28, 0, 0, 0)
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)

    # date_registered -  2022-05-09
    sap_schema = "SAP-Schema-19.1.0".freeze
    sap_xml = Nokogiri.XML Samples.xml(sap_schema, "epc")
    call_lodge_assessment(scheme_id:, schema_name: sap_schema, xml_document: sap_xml, ensure_uprns: false)

    # date_registered = 2023-06-27
    scottish_sap_xml = Samples.xml "SAP-Schema-S-19.0.0"
    scottish_sap_schema = "SAP-Schema-S-19.0.0".freeze
    lodge_scottish_assessment assessment_body: scottish_sap_xml,
                              accepted_responses: [201],
                              scopes: %w[scotland_assessment:lodge migrate:scotland],
                              auth_data: {
                                scheme_ids: [scheme_id],
                              },
                              schema_name: scottish_sap_schema,
                              migrated: true

    schema = "RdSAP-Schema-20.0.0"
    xml = Nokogiri.XML Samples.xml(schema)

    # date_registered = 2020-05-04
    xml.at("RRN").children = "0000-0000-0000-0000-0001"
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)

    xml.at("RRN").children = "0000-0000-0000-0000-0002"
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)

    xml.at("RRN").children = "0000-0000-0000-0000-0003"
    call_lodge_assessment(scheme_id:, schema_name: schema, xml_document: xml, migrated: true)
  end

  after(:all) do
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE assessments CASCADE",
    )
    ActiveRecord::Base.connection.exec_query(
      "TRUNCATE TABLE scotland.assessments CASCADE",
    )
    Timecop.return
  end

  describe "#find_unmatched_assessments" do
    describe "searching for all (non-scotland) assessments" do
      it "returns all assessments with the correct address details" do
        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }]
        expect(helper.find_unmatched_assessments(is_scottish: false, date_to: nil, date_from: nil, skip_existing: false).to_a).to match_array expected_result
      end
    end

    describe "searching for all scottish assessment" do
      it "returns the assessment with the correct address details" do
        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 LOVELY ROAD", "address_line2" => "NICE ESTATE", "address_line3" => "", "address_line4" => nil, "postcode" => "EH1 2NG", "town" => "TOWN" }]
        expect(helper.find_unmatched_assessments(is_scottish: true, date_to: nil, date_from: nil, skip_existing: false).to_a).to match_array expected_result
      end
    end

    describe "skipping assessments that have already been matched" do
      before do
        row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0000")
        row.update_columns(matched_uprn: "199990129")
        row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0001")
        row.update_columns(matched_uprn: "199990129")
      end

      it "does not return values already with a matched uprn" do
        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }]
        expect(helper.find_unmatched_assessments(is_scottish: false, date_to: nil, date_from: nil, skip_existing: true).to_a).to match_array expected_result
      end
    end

    describe "setting both the date parameters" do
      it "only return assessments registered between the dates" do
        date_from = "2022-01-01"
        date_to = "2022-12-01"

        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" }]
        expect(helper.find_unmatched_assessments(is_scottish: false, date_to:, date_from:, skip_existing: false).to_a).to match_array expected_result
      end

      it "only return assessments registered between the dates that do not have a matched uprn" do
        row = Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.find("0000-0000-0000-0000-0001")
        row.update_columns(matched_uprn: "199990129")

        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }]
        expect(helper.find_unmatched_assessments(is_scottish: false, date_to: "2022-01-01", date_from: "2020-01-01", skip_existing: true).to_a).to match_array expected_result
      end
    end

    describe "setting only one of the date parameters" do
      it "ignores the dates and return all assessments" do
        date_from = nil
        date_to = "2022-05-01"

        expected_result = [{ "assessment_id" => "0000-0000-0000-0000-0000", "address_line1" => "1 Some Street", "address_line2" => "Some Area", "address_line3" => "Some County", "address_line4" => nil, "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0001", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0002", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" },
                           { "assessment_id" => "0000-0000-0000-0000-0003", "address_line1" => "1 Some Street", "address_line2" => "", "address_line3" => "", "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "Whitbury" }]
        expect(helper.find_unmatched_assessments(is_scottish: false, date_to:, date_from:, skip_existing: false).to_a).to match_array expected_result
      end
    end
  end
end
