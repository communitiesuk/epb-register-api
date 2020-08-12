# frozen_string_literal: true

describe "Acceptance::LodgeAC-CERT+AC-REPORTNIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd,
                        "spec/fixtures/samples/ac-cert+ac-report-ni.xml"
  end

  context "when lodging an AC-CERT+AC-REPORT assessment (post)" do
    context "when failing so save AC-REPORT as AC-CERT went through" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticCc4: "ACTIVE", nonDomesticSp3: "INACTIVE",
          ),
        )
      end

      it "does not save any lodgement" do
        lodge_assessment(
          assessment_body: valid_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-NI-8.0.0",
        )

        fetch_assessment("0000-0000-0000-0000-0000", [404])

        fetch_assessment("0000-0000-0000-0000-0001", [404])
      end
    end
  end
end
