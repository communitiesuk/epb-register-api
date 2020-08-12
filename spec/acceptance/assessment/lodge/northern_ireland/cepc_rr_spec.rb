# frozen_string_literal: true

describe "Acceptance::LodgeCEPC+RRNIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr-ni.xml"
  end

  context "when lodging an CEPC+RR assessment (post)" do
    context "when failing so save RR even though CEPC went through" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticNos3: "ACTIVE"),
        )
      end

      it "does not save any lodgement" do
        invalid_xml =
          valid_xml.gsub("0000-0000-0000-0000-0001", "0000-0000-0000-0000-0000")

        lodge_assessment(
          assessment_body: invalid_xml,
          accepted_responses: [409],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        fetch_assessment("0000-0000-0000-0000-0000", [404])

        fetch_assessment("0000-0000-0000-0000-0001", [404])
      end
    end
  end
end
