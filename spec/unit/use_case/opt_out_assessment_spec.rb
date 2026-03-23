describe UseCase::OptOutAssessment do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) do
    described_class.new(
      assessments_gateway: Gateway::AssessmentsGateway.new,
      assessments_search_gateway:,
      event_broadcaster: Events::Broadcaster.new,
    )
  end

  let(:assessments_search_gateway) { Gateway::AssessmentsSearchGateway.new }
  let(:assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0000",
      restrictive: false,
    ).first
  end

  let(:scottish_assessment) do
    assessments_search_gateway.search_by_assessment_id(
      "0000-0000-0000-0000-0000",
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

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
    cepc_schema = "CEPC-8.0.0".freeze
    cepc_xml = Nokogiri.XML Samples.xml(cepc_schema, "cepc+rr")
    call_lodge_assessment(scheme_id:, schema_name: cepc_schema, xml_document: cepc_xml)

    scottish_xml = Samples.xml "RdSAP-Schema-S-19.0"
    lodge_assessment(assessment_body: scottish_xml,
                     accepted_responses: [201],
                     scopes: %w[migrate:scotland],
                     auth_data: {
                       scheme_ids: [scheme_id],
                     },
                     schema_name: "RdSAP-Schema-S-19.0",
                     migrated: true)
  end

  context "when not having performed an update" do
    it "the assessment opt out status is false" do
      expect(assessment.get("opt_out")).to be false
    end

    it "the linked assessment opt out status is false" do
      expect(linked_assessment.get("opt_out")).to be false
    end

    it "the scottish assessment opt out status is false" do
      expect(scottish_assessment.get("opt_out")).to be false
    end
  end

  context "when calling update_statuses for opt outs" do
    before do
      use_case.execute("0000-0000-0000-0000-0000", true)
      use_case.execute("0000-0000-0000-0000-0000", true, is_scottish: true)
    end

    it "opts out the assessment by setting the value to true" do
      expect(assessment.get("opt_out")).to be true
    end

    it "opts out the linked assessment by setting the value to true" do
      expect(linked_assessment.get("opt_out")).to be true
    end

    it "the assessment opt out status is false" do
      expect(scottish_assessment.get("opt_out")).to be true
    end
  end

  describe "event broadcasting" do
    around do |test|
      Events::Broadcaster.enable!
      test.run
      Events::Broadcaster.disable!
    end

    context "when an opt out is run with opt_out set to true" do
      it "broadcasts an assessment opt out status changed event with new_status set to true" do
        expect { use_case.execute("0000-0000-0000-0000-0000", true) }.to broadcast(
          :assessment_opt_out_status_changed,
          assessment_id: "0000-0000-0000-0000-0000",
          new_status: true,
          is_scottish: false,
        )
      end
    end

    context "when a Scottish opt out is run with opt_out set to true" do
      it "broadcasts an assessment opt out status changed event with new_status set to true" do
        expect { use_case.execute("0000-0000-0000-0000-0000", true, is_scottish: true) }.to broadcast(
          :assessment_opt_out_status_changed,
          assessment_id: "0000-0000-0000-0000-0000",
          new_status: true,
          is_scottish: true,
        )
      end
    end

    context "when an opt out is run with opt_out set to false" do
      it "broadcasts an assessment opt out status changed event with new_status set to false" do
        expect { use_case.execute("0000-0000-0000-0000-0000", false) }.to broadcast(
          :assessment_opt_out_status_changed,
          assessment_id: "0000-0000-0000-0000-0000",
          new_status: false,
          is_scottish: false,
        )
      end
    end
  end
end
