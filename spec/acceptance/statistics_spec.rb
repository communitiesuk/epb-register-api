describe "Acceptance::AssessmentStatistics", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    add_super_assessor(scheme_id:)

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

    domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-NI-20.0.0")
    rrn = domestic_ni_rdsap_xml.at("RRN")
    rrn.children = "0000-0000-0000-0000-0003"
    ni_postcode = domestic_ni_rdsap_xml.at("Postcode")
    ni_postcode.children = "BT5 2SA"

    lodge_assessment(
      assessment_body: domestic_ni_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "RdSAP-Schema-NI-20.0.0",
      override: true,
    )

    add_countries
    add_assessment_country_ids
    ApiFactory.save_daily_assessments_stats_use_case
              .execute(date: Time.now.strftime("%F"), assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT AC-REPORT])
  end

  context "when calling the statistics data end" do
    it "returns a 200 status" do
      expect(fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      ).status).to eq(200)
    end

    it "produces a json object of the aggregated data" do
      response =   fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments][:all]).to eq([{ assessmentType: "RdSAP", month: Time.now.strftime("%Y-%m"), numAssessments: 3, ratingAverage: 50.0 }])
    end

    it "returns json that contains all the assessments aggregated data for England" do
      response = fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments][:england]).to eq([{ assessmentType: "RdSAP", month: Time.now.strftime("%Y-%m"), numAssessments: 2, ratingAverage: 50.0, country: "England" }])
    end

    it "returns json that contains the assessments aggregated data for Northern Ireland" do
      response = fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments][:northernIreland]).to eq([{ assessmentType: "RdSAP", month: Time.now.strftime("%Y-%m"), numAssessments: 1, ratingAverage: 50.0, country: "Northern Ireland" }])
    end
  end

  context "when calling the calling the statistics data end point with the wrong token" do
    it "returns a 403 status" do
      expect(fetch_statistics(
        accepted_responses: [403],
        scopes: %w[assessments:fetch],
      ).status).to eq(403)
    end
  end

  context "when calling the endpoint with England & Wales in the country for assessment statistics" do
    before do
      Gateway::AssessmentStatisticsGateway::AssessmentStatistics.update_all(country: "England & Wales")
    end

    it "returns json that contains the assessments aggregated data for englandWales" do
      response = fetch_statistics(
        accepted_responses: [200],
        scopes: %w[statistics:fetch],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].key?(:englandWales)).to be true
    end
  end
end
