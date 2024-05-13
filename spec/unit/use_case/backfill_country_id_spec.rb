describe UseCase::BackfillCountryId, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) do
    described_class.new(
      assessment_ids_use_case: UseCase::FetchAssessmentIdForCountryIdBackfill.new(assessments_gateway: Gateway::AssessmentsGateway.new),
      assessments_gateway: Gateway::AssessmentsGateway.new,
      assessments_xml_gateway: Gateway::AssessmentsXmlGateway.new,
      country_use_case: ApiFactory.get_country_for_candidate_assessment_use_case,
      add_country_id_from_address: UseCase::AddCountryIdFromAddress.new(Gateway::CountryGateway.new),
    )
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:assessments) do
    [
      {
        rrn: "0000-0000-0000-0000-0000",
        schema_type: "RdSAP-Schema-20.0.0",
        uprn: "UPRN-100020003000",
      },
      {
        rrn: "0000-0000-0000-0000-0001",
        schema_type: "SAP-Schema-19.0.0",
        uprn: "UPRN-100020004000",
      },
      {
        rrn: "0000-0000-0000-0000-0002",
        schema_type: "SAP-Schema-18.0.0",
        uprn: "UPRN-100020005000",
      },
    ]
  end

  let(:args) do
    {
      date_from: "2020-01-01",
      date_to: "2023-01-31",
    }
  end

  before(:all) do
    add_countries
    add_address_base uprn: "100020003000", postcode: "A0 0AA", country_code: "E"
    add_address_base uprn: "100020004000", postcode: "A0 0AA", country_code: "E"
    add_address_base uprn: "100020005000", postcode: "A0 0AA", country_code: "E"
  end

  before do
    add_super_assessor(scheme_id:)
    assessments.each do |assessment|
      xml = Nokogiri.XML Samples.xml assessment[:schema_type]
      xml.at("RRN").content = assessment[:rrn]
      xml.at("UPRN").content = assessment[:uprn]
      lodge_assessment(
        assessment_body: xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: assessment[:schema_type],
      )
    end
    ActiveRecord::Base.connection.exec_query("UPDATE assessments SET country_id = NULL")
  end

  it "updates the country ids for assessments" do
    use_case.execute(**args)
    result = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as cnt FROM assessments WHERE country_id IS NOT NULL").map { |rows| rows["cnt"] }.first
    expect(result).to eq 3
  end
end
