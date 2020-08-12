# frozen_string_literal: true

describe "Acceptance::LodgeCEPCEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end

  context "when lodging a CEPC assessment (post)" do
    context "when missing building complexity element" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticNos3: "INACTIVE",
            nonDomesticNos4: "INACTIVE",
            nonDomesticNos5: "INACTIVE",
          ),
        )
      end

      it "can return status 400 with the correct error response" do
        doc = Nokogiri.XML valid_cepc_xml

        doc.at("//CEPC:Building-Complexity").remove

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        )
      end
    end

    context "when rejecting an assessment" do
      it "rejects an assessment without an address" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          ),
        )

        doc = Nokogiri.XML valid_cepc_xml

        scheme_assessor_id = doc.at("//CEPC:Property-Address")
        scheme_assessor_id.children = ""

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          schema_name: "CEPC-8.0.0",
        )
      end
    end
  end
end
