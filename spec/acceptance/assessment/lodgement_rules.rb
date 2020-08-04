describe "Acceptance::LodgementRules" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id,
      "SPEC000000",
      fetch_assessor_stub.fetch_request_body(nonDomesticNos3: "ACTIVE"),
    )

    scheme_id
  end

  let(:xml_doc) do
    file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
    Nokogiri.XML(file)
  end

  context "when lodging a CEPC that breaks the rules" do
    it "should reject the assessment" do
      xml_doc.at("//CEPC:Registration-Date").children = Date.tomorrow.to_s
      xml_doc.at("//CEPC:Issue-Date").children = (Date.today << 12 * 5).to_s

      lodge_assessment(
        assessment_body: xml_doc.to_xml,
        accepted_responses: [400],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end
  end
end
