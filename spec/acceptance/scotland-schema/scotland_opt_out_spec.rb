describe "Acceptance::OptOut", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE")
  end

  let(:valid_scottish_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }

  let(:scheme_id) { add_scheme_and_get_id }

  context "when opting out a Scottish domestic assessment" do
    before do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_assessment(assessment_body: valid_scottish_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[migrate:scotland],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "RdSAP-Schema-S-19.0",
                       migrated: true)
    end

    it "requests an opt in and gets the expected response" do
      expect(opt_out_scottish_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        opt_out: false,
      ).body.force_encoding("UTF-8")).to include "Your opt in request for RRN 0000-0000-0000-0000-0000 was successful"
    end

    it "requests an opt out and gets the expected response" do
      expect(opt_out_scottish_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        opt_out: true,
      ).body.force_encoding("UTF-8")).to include "Your opt out request for RRN 0000-0000-0000-0000-0000 was successful"
    end

    it "removes them from the certificate search" do
      response =
        JSON.parse(
          scottish_assessments_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1

      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000")

      response =
        JSON.parse(
          scottish_assessments_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 0
    end

    it "shows as opted out in the assessment summary JSON" do
      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to be true
    end
  end

  context "when opting out a non-domestic Scottish assessment" do
    it "shows as opted out in summary JSON" do
      scheme_id = add_scheme_and_get_id
      xml_file = Samples.xml "CEPC-S-7.1", "cepc"
      assessor =
        AssessorStub.new.fetch_request_body(
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
        )
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)

      lodge_assessment(assessment_body:  xml_file,
                       accepted_responses: [201],
                       scopes: %w[migrate:scotland],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "CEPC-S-7.1",
                       migrated: true)

      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to be true
    end
  end

  context "when opting in a Scottish assessment" do
    it "adds them to the certificate search" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_assessment(assessment_body: valid_scottish_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[migrate:scotland],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "RdSAP-Schema-S-19.0",
                       migrated: true)

      response =
        JSON.parse(
          scottish_assessments_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1

      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000")

      response =
        JSON.parse(
          scottish_assessments_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 0

      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: false)

      response =
        JSON.parse(
          scottish_assessments_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1
    end

    it "shows as opted in the Scottish assessment summary JSON" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
      lodge_assessment(assessment_body: valid_scottish_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[migrate:scotland],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       schema_name: "RdSAP-Schema-S-19.0",
                       migrated: true)
      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000")

      summary =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to be true

      opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: false)

      summary =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(summary[:data][:optOut]).to be false
    end
  end

  context "when opting out an assessment that doesnt exist" do
    it "returns status 404" do
      expect(opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: true, accepted_responses: [404]).status).to eq 404
    end
  end

  context "when opting out an assessment id that is not valid" do
    it "returns status 400" do
      expect(opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-0000%23", opt_out: true, accepted_responses: [400]).status).to eq 400
    end
  end

  context "when opt out value is not a boolean" do
    it "returns status 400" do
      expect(opt_out_scottish_assessment(assessment_id: "0000-0000-0000-0000-000023", opt_out: "true", accepted_responses: [400]).status).to eq 400
    end
  end

  it "returns 400 when body cannot be parsed to JSON" do
    request_body = " something wrong "
    header "Content-type", "application/json"
    response = assertive_request(
      accepted_responses: [400],
      should_authenticate: true,
      auth_data: {},
      scopes: %w[scotland_admin:opt_out],
    ) { put("/api/scotland/assessments/0000-0000-0000-0000-0000/opt-out", request_body) }

    error = JSON.parse(response.body, symbolize_names: true)[:errors].first
    expect(error[:code]).to eq("INVALID_REQUEST")
    expect(error[:title]).to include("unexpected character: 'something'")
  end
end
