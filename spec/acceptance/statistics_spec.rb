describe "Acceptance::AssessmentStatistics", set_with_timecop: true do
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
    rrn = domestic_rdsap_xml.at("RRN")
    rrn.children = "0000-0000-0000-0000-0002"
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      )

    ApiFactory.save_daily_assessments_stats_use_case
              .execute(date: Time.now.strftime("%F"), assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT AC-REPORT])
  end

  context "when calling the statistics data end" do
    it "returns a 200 status" do
      fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      )
    end

  it "produces a json object of the aggregated data" do

    response =   fetch_statistics(
          accepted_responses: [200],
          scopes: %w[statistics:fetch],
          )
    expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq([{:assessmentType=>"RdSAP", :monthYear=>Time.now.strftime("%m-%Y"), :numAssessments=>2, :ratingAverage=>50.0}])
  end
  end

  context "when calling the calling the statistics data end point with the wrong token" do
    it "returns a 403 status" do
      fetch_statistics(
        accepted_responses: [403],
        scopes: %w[assessments:fetch],
      )
    end
  end
end
