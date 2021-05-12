# frozen_string_literal: true

describe "Acceptance::LodgeExamples", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:acic_acir_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-8.0.0(AC-CERT+AC-REPORT).xml"
  end
  let(:acic_acir_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-8.0.0(AC-CERT+AC-REPORT).xml"
  end
  let(:cepc_rr_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-8.0.0(EPC+RR).xml"
  end
  let(:cepc_rr_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-8.0.0(EPC+RR).xml"
  end
  let(:dec_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-8.0.0(DEC).xml"
  end
  let(:ar_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-8.0.0(DEC_RR).xml"
  end
  let(:dec_ar_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-8.0.0(DEC+RR).xml"
  end
  let(:dec_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-8.0.0(DEC).xml"
  end
  let(:ar_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-8.0.0(DEC_RR).xml"
  end
  let(:dec_ar_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-8.0.0(DEC+RR).xml"
  end
  let(:rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-20.0.0.xml"
  end
  let(:rdsap_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-NI-20.0.0.xml"
  end
  let(:sap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/SAP-18.0.0.xml"
  end
  let(:sap_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/SAP-NI-18.0.0.xml"
  end
  let(:scheme_id) { add_scheme_and_get_id }

  describe "when trying to lodge an example XML" do
    before do
      add_assessor(
        scheme_id,
        "JASE000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          domesticSap: "ACTIVE",
          domesticRdSap: "ACTIVE",
        ),
      )
    end

    it "can lodge the example AC-CERT+AC-REPORT" do
      lodge_assessment(
        assessment_body: acic_acir_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "can lodge the example DEC" do
      lodge_assessment(
        assessment_body: dec_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end
    it "can lodge the example DEC Advisory Report" do
      lodge_assessment(
        assessment_body: ar_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "can lodge the example DEC+AR" do
      lodge_assessment(
        assessment_body: dec_ar_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "can lodge the example AC-CERT+AC-REPORT NI" do
      lodge_assessment(
        assessment_body: acic_acir_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    it "can lodge the example CEPC+RR NI" do
      lodge_assessment(
        assessment_body: cepc_rr_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    it "can lodge the example DEC NI" do
      lodge_assessment(
        assessment_body: dec_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    it "can lodge the example DEC Advisory Report NI" do
      lodge_assessment(
        assessment_body: ar_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    it "can lodge the example DEC+AR NI" do
      lodge_assessment(
        assessment_body: dec_ar_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-NI-8.0.0",
      )
    end

    it "can lodge the example RdSAP" do
      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    it "can lodge the example RdSAP NI" do
      lodge_assessment(
        assessment_body: rdsap_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-NI-20.0.0",
      )
    end

    it "can lodge the example SAP" do
      lodge_assessment(
        assessment_body: sap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-18.0.0",
      )
    end

    it "can lodge the example SAP NI" do
      lodge_assessment(
        assessment_body: sap_ni_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-NI-18.0.0",
      )
    end
  end
end
