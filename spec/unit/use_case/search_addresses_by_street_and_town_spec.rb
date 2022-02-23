describe UseCase::SearchAddressesByStreetAndTown, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) { described_class.new }

  context "when arguments include non token characters" do
    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id: scheme_id,
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

      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury")
    end

    it "returns only one address for the relevant property" do
      result = use_case.execute(street: "1 Some Street", town: "Whitbury:!")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000000")
      expect(result.first.line1).to eq("1 Some Street")
      expect(result.first.town).to eq("Whitbury")
      expect(result.first.postcode).to eq("A0 0AA")
    end

    it "returns an error when the params are shorter than 2 after sanitising" do
      expect { use_case.execute(street: "1 Some Street", town: "W:!") }.to raise_error(Boundary::Json::Error)
    end
  end

  context "when searching the same address in both the assessments and address_base tables" do
    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id: scheme_id,
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

      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury")
    end

    it "returns only one address for the relevant property " do
      result = use_case.execute(street: "1 Some Street", town: "Whitbury")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000000")
      expect(result.first.line1).to eq("1 Some Street")
      expect(result.first.town).to eq("Whitbury")
      expect(result.first.postcode).to eq("A0 0AA")
    end
  end

  context "when searching an address not found in the assessment but present in address base" do
    before do
      insert_into_address_base("000000000001", "SW1V 2SS", "2 Some Street", "", "London")
    end

    it "returns a single address line from address base " do
      result = use_case.execute(street: "2 Some Street", town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000001")
      expect(result.first.line1).to eq("2 Some Street")
      expect(result.first.town).to eq("London")
      expect(result.first.postcode).to eq("SW1V 2SS")
    end

    it "returns an address from address base with a fuzzy look up" do
      result = use_case.execute(street: "Some", town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000001")
    end
  end

  context "when there are the same addresses in both the assessments and address base" do
    before do
      insert_into_address_base("000005689782", "SW1 2AA", "Flat 3", "1 Some Street", "London")

      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id: scheme_id,
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

      domestic_assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"

      lodge_assessment(
        assessment_body: domestic_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )
    end

    it "returns only the address from address base not from the assesment" do
      result = use_case.execute(street: "Some", town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000005689782")
    end
  end

  xcontext "when there are the more than one certificate for the same address", set_with_time_cop: true do
    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id: scheme_id,
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

      day_before_yesterday = Time.now.prev_day(2).strftime("%Y-%m-%d")
      domestic_assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      domestic_assessment.at("Inspection-Date").children = day_before_yesterday
      domestic_assessment.at("Completion-Date").children = day_before_yesterday
      domestic_assessment.at("Registration-Date").children = day_before_yesterday
      domestic_assessment.at("Address/Address-Line-1").children = "A New House"
      lodge_assessment(
        assessment_body: domestic_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      yesterday = Time.now.prev_day(1).strftime("%Y-%m-%d")
      domestic_assessment_two = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      domestic_assessment_two.at("RRN").children = "0000-0000-0000-0000-0001"
      domestic_assessment_two.at("Address/Address-Line-1").children = "Another New House"
      domestic_assessment_two.at("RRN").children = "0000-0000-0000-0000-0001"
      domestic_assessment_two.at("Inspection-Date").children = yesterday
      domestic_assessment_two.at("Completion-Date").children = yesterday
      domestic_assessment_two.at("Registration-Date").children = yesterday

      lodge_assessment(
        assessment_body: domestic_assessment_two.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      today = Time.now.strftime("%Y-%m-%d")

      domestic_assessment_three = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      domestic_assessment_three.at("RRN").children = "0000-0000-0000-0000-0001"
      domestic_assessment_three.at("Address/Address-Line-1").children = "1 New House"
      domestic_assessment_three.at("RRN").children = "0000-0000-0000-0000-0002"
      domestic_assessment_two.at("Inspection-Date").children = today
      domestic_assessment_two.at("Completion-Date").children = today
      domestic_assessment_two.at("Registration-Date").children = today

      lodge_assessment(
        assessment_body: domestic_assessment_three.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id
        SET address_id = 'RRN-0000-0000-0000-0000-0000'
        WHERE assessment_id = '0000-0000-0000-0000-0001'")

      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id
        SET address_id = 'RRN-0000-0000-0000-0000-0000'
        WHERE assessment_id = '0000-0000-0000-0000-0002'")
    end

    it "returns the address of newest certificate" do
      result = use_case.execute(street: "New House", town: "Whitbury")
      expect(result.first.address_id).to eq("RRN-0000-0000-0000-0000-0000")
      expect(result.first.line1).to eq("1 New House")
    end

    it "returns the address of newest certificate for postcode search" do
      post_code_use_case = UseCase::SearchAddressesByPostcode.new
      result = post_code_use_case.execute(postcode: "A0 0AA")
      expect(result.first.address_id).to eq("RRN-0000-0000-0000-0000-0000")
      expect(result.first.line1).to eq("1 New House")
    end
  end
end
