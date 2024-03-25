# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    fetch_assessment_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [404])
  end

  it "returns 400 for an assessment id that is not valid" do
    fetch_assessment_summary(id: "0000-0000-0000-0000-0000%23", accepted_responses: [400])
  end

  describe "security scenarios" do
    it "rejects a request that is not authenticated" do
      fetch_assessment_summary(id: "123", accepted_responses: [401], should_authenticate: false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_assessment_summary(id: "124", accepted_responses: [403], scopes: %w[wrong:scope])
    end
  end

  context "when there is dual lodgement" do
    before do
      scheme_id = add_scheme_and_get_id
      xml_file = Samples.xml "CEPC-8.0.0", "cepc+rr"
      assessor =
        AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
        )
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
      cepc_and_rr = Nokogiri.XML(xml_file)

      lodge_assessment(
        assessment_body: cepc_and_rr.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    let(:cepc_response) do
      JSON.parse(
        fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    end

    let(:cepc_rr_response) do
      JSON.parse(
        fetch_assessment_summary(id: "0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
    end

    it "Can give summaries for both documents in a CEPC+RR combo" do
      expect(cepc_response[:data][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(cepc_response[:data][:typeOfAssessment]).to eq("CEPC")
      expect(cepc_rr_response[:data][:assessmentId]).to eq(
        "0000-0000-0000-0000-0001",
      )
      expect(cepc_rr_response[:data][:typeOfAssessment]).to eq("CEPC-RR")
    end

    it "does not have the RR as the superseded EPC" do
      expect(cepc_response[:data][:supersededBy]).to eq(nil)
    end
  end

  context "when fetching a summary" do
    let(:scheme_id) do
      add_scheme_and_get_id
    end

    before do
      xml_file = Samples.xml "CEPC-8.0.0", "cepc+rr"
      assessor =
        AssessorStub.new.fetch_request_body(
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
        )
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
      cepc_and_rr = Nokogiri.XML(xml_file)

      lodge_assessment(
        assessment_body: cepc_and_rr.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "Returns the summary for a URL without hyphens" do
      fetch_assessment_summary(id: "00000000000000000000").body
    end

    it "contains the superseded_by key regardless if there is one" do
      response =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      expect(response[:supersededBy]).to eq(nil)
    end
  end

  context "when Improvement-Heading and Improvement-Summary elements exist" do
    it "returns the Improvement-Heading value as the improvementTitle and falls back to Improvement-Summary" do
      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
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
        migrated: true,
      )

      response =
        JSON.parse(
          fetch_assessment_summary(id: "6666-7777-8888-9999-9999").body,
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
