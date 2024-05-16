shared_context "when extracting the country" do
  def get_country_for_assessment(assessment_id:)
    ActiveRecord::Base.connection.exec_query("SELECT country_name FROM assessments a join countries using(country_id) WHERE assessment_id='#{assessment_id}' ").map { |rows| rows["country_name"] }.first
  end
end

describe UseCase::BackfillCountryId, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin
  subject(:use_case) do
    described_class.new(
      assessment_ids_use_case: UseCase::FetchAssessmentIdForCountryIdBackfill.new(assessments_gateway: Gateway::AssessmentsGateway.new),
      assessments_gateway: Gateway::AssessmentsGateway.new,
      assessments_xml_gateway: Gateway::AssessmentsXmlGateway.new,
      country_use_case: ApiFactory.get_country_for_candidate_backfill_use_case,
      add_country_id_from_address: add_country_use_case,
    )
  end

  include_context "when extracting the country"

  let!(:add_country_use_case) do
    UseCase::AddCountryIdFromAddress.new(Gateway::CountryGateway.new)
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:assessments) do
    [
      {
        rrn: "0000-0000-0000-0000-0000",
        schema_type: "RdSAP-Schema-20.0.0",
        uprn: "UPRN-100020003000",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0001",
        schema_type: "SAP-Schema-19.0.0",
        uprn: "UPRN-100020004000",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0002",
        schema_type: "SAP-Schema-18.0.0",
        uprn: "UPRN-100020005000",
      },
      {
        rrn: "0000-0000-0000-0000-0003",
        schema_type: "SAP-Schema-17.1",
        registered_date: "2010-05-04",
        uprn: "1000200099",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0004",
        schema_type: "CEPC-8.0.0",
        type: "cepc-rr",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0005",
        schema_type: "CEPC-3.1",
        type: "cepc-rr",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0006",
        schema_type: "CEPC-4.0",
        type: "dec",
        postcode: "SW1 0AA",
      },
      {
        rrn: "0000-0000-0000-0000-0007",
        schema_type: "RdSAP-Schema-NI-20.0.0",
      },
      {
        rrn: "0000-0000-0000-0000-0008",
        schema_type: "RdSAP-Schema-19.0",
        postcode: "DG1 2DE",
        uprn: "1000200090",
      },
      {
        rrn: "0000-0000-0000-0000-0009",
        schema_type: "RdSAP-Schema-19.0",
        uprn: "1000200066",
      },
      {
        rrn: "0000-0000-0000-0000-0010",
        schema_type: "SAP-Schema-11.0",
        type: "sap",
      },
      {
        rrn: "0000-0000-0000-0000-0011",
        schema_type: "SAP-Schema-10.2",
        type: "rdsap",
      },
      {
        rrn: "0000-0000-0000-0000-0012",
        schema_type: "SAP-Schema-16.1",
        type: "rdsap",
        postcode: "XX1 1XX",
      },
      {
        rrn: "0000-0000-0000-0000-0013",
        schema_type: "CEPC-7.0",
        type: "ac-report",
        postcode: "SW1 0AA",
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
    add_address_base uprn: "100020003000", postcode: "SW1 0AA", country_code: "E"
    add_address_base uprn: "100020004000", postcode: "SW1 0AA", country_code: "E"
    add_address_base uprn: "100020005000", postcode: "SW1 0AA", country_code: "E"
    add_address_base uprn: "1000200099",   postcode: "SW1 0AA", country_code: "E"
    add_address_base uprn: "199999999999", postcode: "BT1 2DE", country_code: "N"
    add_address_base uprn: "999999999999", postcode: "XX1 1XX", country_code: "E"
  end

  before do
    add_super_assessor(scheme_id:)
    assessments.each do |assessment|
      xml = assessment[:type].nil? ? (Nokogiri.XML Samples.xml assessment[:schema_type]) : (Nokogiri.XML Samples.xml assessment[:schema_type], assessment[:type])
      xml.at("//*[local-name() = 'RRN']").content = assessment[:rrn]
      xml.at("//*[local-name() = 'UPRN']").content = assessment[:uprn] if assessment[:uprn]
      xml.at("Registration-Date").content = assessment[:registered_date] if assessment[:registered_date]

      lodge_assessment(
        assessment_body: xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: assessment[:schema_type],
      )
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET postcode = '#{assessment[:postcode]}' WHERE assessment_id='#{assessment[:rrn]}'") if assessment[:postcode]
    end
    ActiveRecord::Base.connection.exec_query("UPDATE assessments SET country_id = NULL")
  end

  it "updates every row in the assessments table within the date range with the relevant country_id(s)" do
    use_case.execute(**args)
    number_in_range = (assessments.length - 1)
    count = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as cnt FROM assessments WHERE country_id IS NOT NULL").map { |rows| rows["cnt"] }.first
    expect(count).to eq number_in_range
  end

  it "updates the country_id with a BT* post code to Northern Ireland" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0007")).to eq "Northern Ireland"
  end

  it "updates the country_id with Scottish post code to Scotland" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0008")).to eq "Scotland"
  end

  it "updates the country_id for the RdSAP EPC using the XML" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0009")).to eq "England and Wales"
  end

  it "updates the country_id for the SAP 11 EPC using the XML" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0010")).to eq "England and Wales"
  end

  it "updates the country_id for SAP 10.2 with no uprn, postcode or xml country code" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0011")).to eq "Unknown"
  end

  it "updates the country_id for SAP 16.2 using address base rather than the postcode matcher" do
    use_case.execute(**args)
    expect(get_country_for_assessment(assessment_id: "0000-0000-0000-0000-0012")).to eq "England"
  end

  context "when filtering by assessment_types" do
    it "updates the country_id only for the RdSAPs within the date range" do
      args[:assessment_types] = %w[RdSAP]
      use_case.execute(**args)
      result = ActiveRecord::Base.connection.exec_query("SELECT assessment_id  FROM assessments WHERE country_id IS NOT NULL and type_of_assessment='RdSAP'").map { |rows| rows["assessment_id"] }
      expect(result.length).to eq 6
    end
  end

  context "when no data is found" do
    let(:args) do
      {
        date_from: "3025-01-01",
        date_to: "3026-01-31",
      }
    end

    it "raises a no assessment error" do
      expect { use_case.execute(**args) }.to raise_error Boundary::NoAssessments
    end
  end

  context "when the dates are out of bounds" do
    let(:args) do
      {
        date_from: "2024-10-01",
        date_to: "2024-01-31",
      }
    end

    it "raises a no assessment error" do
      expect { use_case.execute(**args) }.to raise_error Boundary::InvalidDates
    end
  end
end
