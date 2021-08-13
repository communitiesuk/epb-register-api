describe "Acceptance::AssessmentMeta" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")

    add_assessor(
      scheme_id,
      "SPEC000000",
      AssessorStub.new.fetch_request_body(
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
      override: true,
    )
  end

  it "returns a 200 when calling the meta data end point" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0000", [200], true, {}, %w[assessmentmetadata:fetch])
  end

  it "returns a 404 when calling the meta data end point and returns no data" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0001", [404], true, {}, %w[assessmentmetadata:fetch])
  end

  it "returns a 403 when calling the meta data end point with the wrong scopes" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0001", [403], true, %w[wrong:scope])
  end
end
