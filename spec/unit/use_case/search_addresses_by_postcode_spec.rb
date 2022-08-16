describe UseCase::SearchAddressesByPostcode, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) { described_class.new }

  context "when arguments include non token characters" do
    before do
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

      second_asessment = assessment
      second_asessment.at("RRN").children = "0000-0000-0000-0000-0001"

      lodge_assessment(
        assessment_body: second_asessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury", "E")
      insert_into_address_base("000000000001", "S1 0AA", "31 Barry's Street", "", "London", "E")
    end

    context "when searching with a buildingNameNumber string prefixed by a valid, existing street number" do
      it "returns only one address for the relevant property" do
        result = use_case.execute(postcode: "A0 0AA", building_name_number: "1():*!&\\")

        expect(result.length).to eq(1)
        expect(result.first.address_id).to eq("UPRN-000000000000")
        expect(result.first.line1).to eq("1 Some Street")
        expect(result.first.town).to eq("Whitbury")
        expect(result.first.postcode).to eq("A0 0AA")
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
