describe UseCase::UpdateAssessmentStatus do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { described_class.new }

  let(:assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0000",
      false,
    ).first
  end

  let(:linked_assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0001",
      false,
    ).first
  end

  before(:all) do
    @scheme_id = add_scheme_and_get_id
    add_super_assessor(@scheme_id)
    cepc_schema = "CEPC-8.0.0".freeze
    cepc_xml = Nokogiri.XML Samples.xml(cepc_schema, "cepc+rr")
    call_lodge_assessment(scheme_id: @scheme_id, schema_name: cepc_schema, xml_document: cepc_xml)
  end

  context "when calling update_statuses" do
    let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }

    before do
      use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [@scheme_id])
    end

    it "cancels the first assessment" do
      expect(assessment.get("cancelled_at")).not_to be_nil
    end

    it "cancels the linked assessment" do
      expect(linked_assessment.get("cancelled_at")).not_to be_nil
    end
  end

  context "when one half of a linked pair is already cancelled" do
    let(:assessments_gateway) { Gateway::AssessmentsGateway.new }
    let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
    before do
      assessments_gateway.update_statuses(
        %w[0000-0000-0000-0000-0001],
        "cancelled_at",
        Time.now.to_s,
      )
    end

    it "cancels the uncancelled certificate" do
      use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [@scheme_id])
      expect(assessment.get("cancelled_at")).not_to be_nil
    end
  end
end
