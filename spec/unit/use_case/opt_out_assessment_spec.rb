describe UseCase::OptOutAssessment do
  include RSpecRegisterApiServiceMixin

  let(:use_case) { described_class.new }
  let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
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
    call_lodge_assessment(@scheme_id, cepc_schema, cepc_xml)
  end

  context "before the update has taken place" do
    it "the assesment opt out status is false" do
      expect(assessment.get("opt_out")).to be false
    end
    it "the linked assement opt out status is false" do
      expect(linked_assessment.get("opt_out")).to be false
    end
  end

  context "when calling update_statuses for opt outs" do
    before { use_case.execute("0000-0000-0000-0000-0000") }

    it "opts out the assessment by setting the value to true" do
      expect(assessment.get("opt_out")).to be true
    end

    it "opts out the linked assessment by setting the value to true" do
      expect(linked_assessment.get("opt_out")).to be true
    end
  end
end
