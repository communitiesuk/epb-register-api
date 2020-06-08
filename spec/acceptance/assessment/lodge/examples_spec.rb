# frozen_string_literal: true

describe "Acceptance::LodgeExamples" do
  include RSpecAssessorServiceMixin

  let(:acic_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(ACIC).xml"
  end
  let(:acic_acir_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-7.11(ACIC+ACIR).xml"
  end
  let(:acir_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(ACIR).xml"
  end
  let(:ar_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(AR).xml"
  end
  let(:dec_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(DEC).xml"
  end
  let(:cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(EPC).xml"
  end
  let(:rr_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(RR).xml"
  end
  let(:acic_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-7.11(ACIC).xml"
  end
  let(:acir_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-7.11(ACIR).xml"
  end
  let(:ar_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-NI-7.11(AR).xml"
  end
  let(:dec_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-7.11(DEC).xml"
  end
  let(:cepc_ni_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-NI-7.11(EPC).xml"
  end
  let(:rr_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-NI-7.11(RR).xml"
  end
  let(:rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end
  let(:rdsap_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-NI-19.01.xml"
  end
  let(:sap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/SAP-17.11.xml"
  end
  let(:sap_ni_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/SAP-NI-17.41.xml"
  end
  let(:dec_ar_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-7.11(DEC+AR).xml"
  end
  let(:cepc_rr_xml) do
    File.read File.join Dir.pwd,
                        "api/schemas/xml/examples/CEPC-7.11(EPC+RR).xml"
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

    it "can lodge the example ACIC" do
      lodge_assessment(
        assessment_body: acic_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example ACIC+ACIR" do
      lodge_assessment(
        assessment_body: acic_acir_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example ACIR" do
      lodge_assessment(
        assessment_body: acir_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example DEC Advisory Report" do
      lodge_assessment(
        assessment_body: ar_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example DEC" do
      lodge_assessment(
        assessment_body: dec_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example CEPC" do
      lodge_assessment(
        assessment_body: cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example CEPC Recommendation Report" do
      lodge_assessment(
        assessment_body: rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example ACIC NI" do
      lodge_assessment(
        assessment_body: acic_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example ACIR NI" do
      lodge_assessment(
        assessment_body: acir_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example DEC Advisory Report NI" do
      lodge_assessment(
        assessment_body: ar_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example DEC NI" do
      lodge_assessment(
        assessment_body: dec_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example CEPC NI" do
      lodge_assessment(
        assessment_body: cepc_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example CEPC Recommendation Report" do
      lodge_assessment(
        assessment_body: rr_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-7.1",
      )
    end

    it "can lodge the example RdSAP" do
      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "RdSAP-Schema-19.0",
      )
    end

    it "can lodge the example RdSAP NI" do
      lodge_assessment(
        assessment_body: rdsap_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "RdSAP-Schema-NI-19.0",
      )
    end

    it "can lodge the example SAP" do
      lodge_assessment(
        assessment_body: sap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-17.1",
      )
    end

    it "can lodge the example SAP NI" do
      lodge_assessment(
        assessment_body: sap_ni_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-NI-17.4",
      )
    end

    it "can lodge the example DEC+AR" do
      lodge_assessment(
        assessment_body: dec_ar_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "can lodge the example CEPC+RR" do
      lodge_assessment(
        assessment_body: cepc_rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end
  end
end
