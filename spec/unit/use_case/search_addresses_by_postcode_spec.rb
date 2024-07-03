describe UseCase::SearchAddressesByPostcode, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) { described_class.new }

  context "when arguments include non token characters" do
    before do
      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury", "E")
      insert_into_address_base("000000000001", "S1 0AA", "31 Barry's Street", "", "London", "E")

      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id:,
        assessor_id: "SPEC000000",
        body: AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          gda: "ACTIVE",
        ),
      )

      assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      second_assessment = assessment
      second_assessment.at("RRN").children = "0000-0000-0000-0000-0001"

      lodge_assessment(
        assessment_body: second_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      third_assessment = assessment
      third_assessment.at("RRN").children = "0000-0000-0000-0000-0003"
      third_assessment.at("UPRN").children = "UPRN-000000000003"
      third_assessment.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "2 Some Street" }

      lodge_assessment(
        assessment_body: third_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id='UPRN-000000000003', source='os_lprn2uprn' WHERE assessment_id = '0000-0000-0000-0000-0003'")
    end

    context "when searching with a buildingNameNumber string prefixed by a valid, existing street number" do
      it "returns only one address for the relevant property" do
        result = use_case.execute(postcode: "A0 0AA", building_name_number: "1():*!&\\")

        expect(result.length).to eq(2)
        expect(result.first.address_id).to eq("UPRN-000000000000")
        expect(result.first.line1).to eq("1 Some Street")
        expect(result.first.town).to eq("Whitbury")
        expect(result.first.postcode).to eq("A0 0AA")
        expect(result.first.source).to eq("GAZETTEER")
      end
    end

    context "when searching for an address lodged with a UPRN that doesn't exist in address base" do
      it "returns previous assessment as the source" do
        result = use_case.execute(postcode: "A0 0AA")

        expect(result.length).to eq(2)
        expect(result.last.address_id).to eq("UPRN-000000000003")
        expect(result.last.source).to eq("PREVIOUS_ASSESSMENT")
      end
    end

    context "when searching with a buildingNameNumber containing just a single quote" do
      it "does not error" do
        expect { use_case.execute(postcode: "A0 0AA", building_name_number: "'") }.not_to raise_error
      end
    end

    context "when the address already contains an apostrophe" do
      it "returns only one address for the relevant property" do
        result = use_case.execute(postcode: "S1 0AA", building_name_number: "Barry's Street")
        expect(result.length).to eq(1)
      end
    end
  end
end
