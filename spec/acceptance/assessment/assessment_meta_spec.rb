describe "Acceptance::AssessmentMeta" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")

    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(
        non_domestic_nos3: "ACTIVE",
        non_domestic_nos4: "ACTIVE",
        non_domestic_nos5: "ACTIVE",
        non_domestic_dec: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
        non_domestic_sp3: "ACTIVE",
        non_domestic_cc4: "ACTIVE",
        gda: "ACTIVE",
      ),
    )

    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )
  end

  it "returns a 200 when calling the meta data end point" do
    expect(fetch_assessment_meta_data(
      assessment_id: "0000-0000-0000-0000-0000",
      accepted_responses: [200],
      scopes: %w[assessmentmetadata:fetch],
    ).status).to eq(200)
  end

  it "returns a 404 when calling the meta data end point and returns no data" do
    expect(fetch_assessment_meta_data(
      assessment_id: "0000-0000-0000-0000-0001",
      accepted_responses: [404],
      scopes: %w[assessmentmetadata:fetch],
    ).status).to eq(404)
  end

  it "returns a 403 when calling the meta data end point with the wrong scopes" do
    expect(fetch_assessment_meta_data(
      assessment_id: "0000-0000-0000-0000-0001",
      accepted_responses: [403],
      scopes: %w[wrong:scope],
    ).status).to eq(403)
  end
end
