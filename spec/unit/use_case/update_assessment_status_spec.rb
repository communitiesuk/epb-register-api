describe UseCase::UpdateAssessmentStatus do
  include RSpecRegisterApiServiceMixin

  scheme_id = nil

  subject(:use_case) do
    described_class.new(
      assessments_gateway:,
      assessments_search_gateway:,
      assessors_gateway: Gateway::AssessorsGateway.new,
      event_broadcaster: Events::Broadcaster.new,
    )
  end

  let(:assessments_gateway) { Gateway::AssessmentsGateway.new }

  let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }

  let(:assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0000",
      restrictive: false,
    ).first
  end

  let(:scottish_assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0040",
      restrictive: false,
      is_scottish: true,
    ).first
  end

  let(:linked_assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0001",
      restrictive: false,
    ).first
  end

  let(:scottish_linked_assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0050",
      restrictive: false,
      is_scottish: true,
    ).first
  end

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
    cepc_schema = "CEPC-8.0.0".freeze
    cepc_xml = Nokogiri.XML Samples.xml(cepc_schema, "cepc+rr")
    call_lodge_assessment(scheme_id:, schema_name: cepc_schema, xml_document: cepc_xml)

    lodge_assessment(
      assessment_body: Samples.xml("DECAR-S-7.0", "dec+ar"),
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "DECAR-S-7.0",
      migrated: true,
    )
  end

  context "when calling update_statuses" do
    before do
      use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [scheme_id])
    end

    it "cancels the first assessment" do
      expect(assessment.get("cancelled_at")).not_to be_nil
    end

    it "cancels the linked assessment" do
      expect(linked_assessment.get("cancelled_at")).not_to be_nil
    end
  end

  context "when calling update_statuses for Scottish assessments" do
    before do
      use_case.execute("0000-0000-0000-0000-0040", "CANCELLED", [scheme_id], is_scottish: true)
    end

    it "cancels the first scottish assessment" do
      expect(scottish_assessment.get("cancelled_at")).not_to be_nil
    end

    it "cancels the linked scottish assessment" do
      expect(scottish_linked_assessment.get("cancelled_at")).not_to be_nil
    end
  end

  context "when one half of a linked pair is already cancelled" do
    before do
      assessments_gateway.update_statuses(
        %w[0000-0000-0000-0000-0001],
        "cancelled_at",
        Time.now.to_s,
      )
    end

    it "cancels the uncancelled certificate" do
      use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [scheme_id])
      expect(assessment.get("cancelled_at")).not_to be_nil
    end
  end

  describe "event broadcasting" do
    around do |test|
      Events::Broadcaster.enable!
      test.run
      Events::Broadcaster.disable!
    end

    context "when an assessment is cancelled" do
      it "broadcasts an assessment_cancelled event" do
        expect { use_case.execute("0000-0000-0000-0000-0000", "CANCELLED", [scheme_id]) }.to broadcast(:assessment_cancelled, assessment_id: "0000-0000-0000-0000-0000", is_scottish: false)
      end

      it "broadcasts an assessment_cancelled event for a Scottish assessment" do
        expect { use_case.execute("0000-0000-0000-0000-0040", "CANCELLED", [scheme_id], is_scottish: true) }.to broadcast(:assessment_cancelled, assessment_id: "0000-0000-0000-0000-0040", is_scottish: true)
      end
    end

    context "when an assessment is marked not for issue" do
      it "broadcasts an assessment_marked_not_for_issue event" do
        expect { use_case.execute("0000-0000-0000-0000-0000", "NOT_FOR_ISSUE", [scheme_id]) }.to broadcast(:assessment_marked_not_for_issue, assessment_id: "0000-0000-0000-0000-0000", is_scottish: false)
      end

      it "broadcasts an assessment_marked_not_for_issue event for a Scottish assessment" do
        expect { use_case.execute("0000-0000-0000-0000-0040", "NOT_FOR_ISSUE", [scheme_id], is_scottish: true) }.to broadcast(:assessment_marked_not_for_issue, assessment_id: "0000-0000-0000-0000-0040", is_scottish: true)
      end
    end
  end
end
