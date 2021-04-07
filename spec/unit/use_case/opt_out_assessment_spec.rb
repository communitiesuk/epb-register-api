describe UseCase::OptOutAssessment do
  include RSpecRegisterApiServiceMixin

  CEPC_SCHEMA = "CEPC-8.0.0".freeze

  let(:use_case) { described_class.new }

  before(:all) do
    @scheme_id = add_scheme_and_get_id
    add_super_assessor(@scheme_id)
    cepc_xml = Nokogiri.XML Samples.xml(CEPC_SCHEMA, "cepc+rr")
    call_lodge_assessment(@scheme_id, CEPC_SCHEMA, cepc_xml)
  end

  context "when calling update_statuses for opt outs" do
    let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
    before do
      use_case.execute("0000-0000-0000-0000-0000")
    end

    it "it opts out the first assessment" do
      assessment1 =
        assessments_search_gateway.search_by_assessment_id(
          "0000-0000-0000-0000-0000",
          false,
        ).first
      expect(assessment1.get("opt_out")).to be true
    end

    it "it opts out the linked assessment" do
      assessment2 =
        assessments_search_gateway.search_by_assessment_id(
          "0000-0000-0000-0000-0001",
          false,
        ).first
      expect(assessment2.get("opt_out")).to be true
    end
  end
end
