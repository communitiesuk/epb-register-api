describe "Acceptance::OptOut", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(domestic_rd_sap: "ACTIVE")
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when opting out an assessment" do
    it "removes them from the certificate search" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 0
    end

    it "shows as opted out in the assessment summary JSON" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to eq true
    end

    it "shows as opted out in commercial assessment summary JSON" do
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

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to eq true
    end
  end

  context "when opting in an assessment" do
    it "adds them to the certificate search" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 0

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: false)

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1
    end

    it "shows as opted in in the assessment summary JSON" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to eq true

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: false)

      summary =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to eq false
    end
  end

  context "when opting out an assessment that doesnt exist" do
    it "returns 404" do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: true, accepted_responses: [404])
    end
  end

  context "when opting out an assessment id that is not valid" do
    it "returns 400" do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000%23", opt_out: true, accepted_responses: [400])
    end
  end

  context "when opt out value is not a boolean" do
    it "returns 400" do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-000023", opt_out: "true", accepted_responses: [400])
    end
  end

  it "returns 400 when body cannot be parsed to JSON" do
    request_body = " something wrong "
    response = assertive_request(
      accepted_responses: [400],
      should_authenticate: true,
      auth_data: {},
      scopes: %w[admin:opt_out],
    ) { put("/api/assessments/0000-0000-0000-0000-0000/opt-out", request_body) }

    error = JSON.parse(response.body, symbolize_names: true)[:errors].first

    expect(error[:code]).to eq("INVALID_REQUEST")
    expect(error[:title]).to include("unexpected token at 'something wrong '")
  end
end
