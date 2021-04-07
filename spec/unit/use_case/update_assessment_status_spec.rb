describe UseCase::UpdateAssessmentStatus do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { described_class.new }

  before(:all) do
    @scheme_id = add_scheme_and_get_id
    add_super_assessor(@scheme_id)
    cepc_schema = "CEPC-8.0.0".freeze
    cepc_xml = Nokogiri.XML Samples.xml(cepc_schema, "cepc+rr")
    call_lodge_assessment(@scheme_id, cepc_schema, cepc_xml)
  end

  context "when calling update_statuses" do
    let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
    before do
      use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [@scheme_id])
    end

    it "it cancels the first assessment" do
      assessment1 =
        assessments_search_gateway.search_by_assessment_id(
          "0000-0000-0000-0000-0000",
          false,
        ).first
      expect(assessment1.get("cancelled_at")).not_to be_nil
    end

    it "it cancels the linked assessment" do
      assessment2 =
        assessments_search_gateway.search_by_assessment_id(
          "0000-0000-0000-0000-0001",
          false,
        ).first
      expect(assessment2.get("cancelled_at")).not_to be_nil
    end
  end
end
