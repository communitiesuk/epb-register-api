describe "Acceptance::AssessmentStatistics" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    add_super_assessor(scheme_id: scheme_id)

    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )
  end

  it "returns a 200 when calling the statistics data end point" do
    fetch_statistics(
      accepted_responses: [200],
      scopes: %w[statistics:fetch],
    )
  end

  it "returns a 403 when calling the statistics data with the wrong scope" do
    fetch_statistics(
      accepted_responses: [403],
      scopes: %w[assessments:fetch],
    )
  end
end
