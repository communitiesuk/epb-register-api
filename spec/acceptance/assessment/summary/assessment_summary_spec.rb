# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    fetch_assessment_summary("0000-0000-0000-0000-0000", [404])
  end

  it "returns 400 for an assessment id that is not valid" do
    fetch_assessment_summary("0000-0000-0000-0000-0000%23", [400])
  end

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_assessment_summary("123", [401], false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_assessment_summary("124", [403], true, {}, %w[wrong:scope])
    end
  end

  context "dual lodgement" do
    it "Can give summaries for both documents in a CEPC+RR combo" do
      scheme_id = add_scheme_and_get_id
      xml_file = Samples.xml "CEPC-8.0.0", "cepc+rr"
      assessor =
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
        )
      add_assessor(scheme_id, "SPEC000000", assessor)
      cepc_and_rr = Nokogiri.XML(xml_file)

      lodge_assessment(
        assessment_body: cepc_and_rr.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      cepc_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      cepc_rr_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )

      expect(cepc_response[:data][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(cepc_response[:data][:typeOfAssessment]).to eq("CEPC")
      expect(cepc_rr_response[:data][:assessmentId]).to eq(
        "0000-0000-0000-0000-0001",
      )
      expect(cepc_rr_response[:data][:typeOfAssessment]).to eq("CEPC-RR")
    end
  end

  context "RRN format" do
    it "Returns the summary for a URL without hyphens" do
      scheme_id = add_scheme_and_get_id
      xml_file = Samples.xml "CEPC-8.0.0", "cepc+rr"
      assessor =
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
        )
      add_assessor(scheme_id, "SPEC000000", assessor)
      cepc_and_rr = Nokogiri.XML(xml_file)

      lodge_assessment(
        assessment_body: cepc_and_rr.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      fetch_assessment_summary("00000000000000000000").body
    end
  end

  context "when Improvement-Heading and Improvement-Summary elements exist" do
    it "returns the Improvement-Heading value as the improvementTitle and falls back to Improvement-Summary" do
      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
        )
      add_assessor(scheme_id, "SPEC000000", assessor)
      lodge_assessment(
        assessment_body:
          Samples.xml(
            "Additional-Fixtures",
            "sap_with_improvement_headings_and_summaries",
          ),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-13.0",
      )

      response =
        JSON.parse(
          fetch_assessment_summary("6666-7777-8888-9999-9999", [200]).body,
          symbolize_names: true,
        )
      improvements = response[:data][:recommendedImprovements]
      expect(improvements.length).to eq(4)
      expect(improvements[0][:improvementTitle]).to eq "Loft insulation" # From Improvement-Heading
      expect(
        improvements[1][:improvementTitle],
      ).to eq "Increase hot water cylinder insulation" # From Improvement-Summary
      expect(improvements[2][:improvementTitle]).to eq "Low energy lighting" # From Improvement-Heading
      expect(
        improvements[3][:improvementTitle],
      ).to eq "Hot water cylinder thermostat" # From Improvement-Summary
    end
  end
end
