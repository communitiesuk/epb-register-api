describe "Acceptance::ExtractionMethodTransition" do
  include RSpecRegisterApiServiceMixin

  context "for getting SAP lodgements" do
    let(:valid_sap_xml) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
    end

    let(:fetch_assessor_stub) { AssessorStub.new }
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE")

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-18.0.0"
    end

    it "has a 100% match between the two endpoints" do
      old_endpoint =
        JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
      new_endpoint =
        JSON.parse fetch_assessment_summary("0000-0000-0000-0000-0000").body

      old_endpoint["data"].each do |key, value|
        expect(new_endpoint["data"][key]).to eq(value)
      end
    end
  end

  context "for getting RdSAP lodgements" do
    let(:valid_rdsap_xml) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
    end

    let(:fetch_assessor_stub) { AssessorStub.new }
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(
                     domesticRdSap: "ACTIVE",
                   )

      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "RdSAP-Schema-20.0.0"
    end

    it "has a 100% match between the two endpoints" do
      old_endpoint =
        JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
      new_endpoint =
        JSON.parse fetch_assessment_summary("0000-0000-0000-0000-0000").body

      old_endpoint["data"].each do |key, value|
        expect(new_endpoint["data"][key]).to eq(value)
      end
    end
  end
end
