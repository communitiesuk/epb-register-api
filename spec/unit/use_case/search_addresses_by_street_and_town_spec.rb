describe UseCase::SearchAddressesByStreetAndTown, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) { described_class.new }

  let!(:scheme_id) do
    add_scheme_and_get_id
  end

  context "when arguments include non token characters" do
    before do
      add_super_assessor(scheme_id:)
      assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury", "E")
    end

    it "returns only one address for the relevant property" do
      result = use_case.execute(street: "1 Some Street", town: "Whitbury:!\\")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000000")
      expect(result.first.line1).to eq("1 Some Street")
      expect(result.first.town).to eq("Whitbury")
      expect(result.first.postcode).to eq("A0 0AA")
    end

    it "returns an error when the params are shorter than 2 after sanitising" do
      expect { use_case.execute(street: "1 Some Street", town: "W:!") }.to raise_error(
        Boundary::Json::Error,
        "Values must have minimum 2 alphanumeric characters",
      )
    end
  end

  context "when searching the same address in both the assessments and address_base tables" do
    before do
      add_super_assessor(scheme_id:)
      assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      insert_into_address_base("000000000000", "A0 0AA", "1 Some Street", "", "Whitbury", "E")
    end

    it "returns only one address for the relevant property" do
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
      insert_into_address_base("000000000001", "SW1V 2SS", "2 Some Street", "", "London", "E")
    end

    it "returns a single address line from address base" do
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
      add_super_assessor(scheme_id:)
      insert_into_address_base("000005689782", "SW1 2AA", "Flat 3", "1 Some Street", "London", "E")
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

    it "returns only the address from address base not from the assessment" do
      result = use_case.execute(street: "Some", town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000005689782")
    end
  end
end
