require "rspec"

describe "Gateway::AssessmentsGateway" do
  include RSpecRegisterApiServiceMixin

  CEPC_SCHEMA = "CEPC-8.0.0".freeze

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id)

    cepc_xml = Nokogiri.XML Samples.xml(CEPC_SCHEMA, "cepc+rr")

    call_lodge_assessment(scheme_id, CEPC_SCHEMA, cepc_xml)
  end

  context "given a dual lodgement" do
    let(:assessment_gateway) { Gateway::AssessmentsGateway.new }

    context "calling get_linked_assessment_id on both assessments" do
      it "will return the first assessment's linked assessment counterpart" do
        expect(
          assessment_gateway.get_linked_assessment_id(
            "0000-0000-0000-0000-0000",
          ),
        ).to eq("0000-0000-0000-0000-0001")
      end

      it "will return the second assessment's linked assessment counterpart" do
        expect(
          assessment_gateway.get_linked_assessment_id(
            "0000-0000-0000-0000-0001",
          ),
        ).to eq("0000-0000-0000-0000-0000")
      end
    end

    context "calling update_statuses on both assessments" do
      let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
      assessments = %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001]
      field = "cancelled_at"

      it "it cancels the first assessment" do
        assessment_gateway.update_statuses(assessments, field, Time.now.to_s)
        assessment1 = assessments_search_gateway.search_by_assessment_id(assessments[0], false, ["CEPC"])
        expect(assessment1.get("cancelled_at")).to eq("")
      end

      xit "it cancels the second assessment" do
      end
    end
  end
end
