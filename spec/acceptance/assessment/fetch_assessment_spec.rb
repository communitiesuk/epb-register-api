# frozen_string_literal: true

require "date"

describe "Acceptance::Assessment", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:green_deal_plan_stub) { GreenDealPlansGatewayStub.new }

  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }

  let(:sanitised_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/sap.xml"
  end

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_assessment("123", [401], false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_assessment("124", [403], true, {}, %w[wrong:scope])
    end
  end

  context "when a domestic assessment doesnt exist" do
    let(:response) do
      JSON.parse fetch_assessment("9999-9999-9999-9999-9999", [404]).body
    end

    it "returns status 404 for a get" do
      fetch_assessment("9999-9999-9999-9999-9999", [404])
    end

    it "returns an error message structure" do
      expect(response).to eq(
        {
          "errors" => [
            { "code" => "NOT_FOUND", "title" => "Assessment not found" },
          ],
        },
      )
    end
  end

  context "when the assessment ID is badly formatted" do
    let(:response) { JSON.parse fetch_assessment("NOT-AN-RRN", [400]).body }

    it "returns status 400 for a get" do
      fetch_assessment("NOT-AN-RRN", [400])
    end

    it "returns an error message structure" do
      expect(response).to eq(
        {
          "errors" => [
            {
              "code" => "INVALID_REQUEST",
              "title" => "The requested assessment id is not valid",
            },
          ],
        },
      )
    end
  end

  context "when a domestic assessment exists" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:response) do
      JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE")

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
    end

    context "when requesting an assessments XML" do
      let(:response) do
        fetch_assessment(
          "0000-0000-0000-0000-0000",
          [200],
          true,
          { 'scheme_ids': [scheme_id] },
          %w[assessment:fetch],
          headers: {
            "Accept": "application/xml",
          },
        )
      end

      it "returns the XML as expected" do
        expect(
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + response.body,
        ).to eq(sanitised_sap_xml)
      end
    end
  end

  context "When schemes attempt to download data lodged by another scheme" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:other_scheme_id) { add_scheme_and_get_id("another one") }
    let(:response) do
      JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE")

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "SAP-Schema-18.0.0"
    end

    it "will not allow another scheme to download another schemes lodeged data" do
      fetch_assessment(
        "0000-0000-0000-0000-0000",
        [403],
        true,
        { 'scheme_ids': [other_scheme_id] },
        %w[assessment:fetch],
        headers: {
          "Accept": "application/xml",
        },
      )
    end
  end
end
