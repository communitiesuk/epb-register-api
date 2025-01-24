shared_context "when extracting the country" do
  def get_country_for_assessment(assessment_id:)
    ActiveRecord::Base.connection.exec_query("SELECT country_name FROM assessments_country_ids a join countries using(country_id) WHERE assessment_id='#{assessment_id}' ").map { |rows| rows["country_name"] }.first
  end
end

describe UseCase::UpdateCountryId, :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  subject(:use_case) do
    described_class.new(
      assessments_gateway: Gateway::AssessmentsGateway.new,
      country_use_case: ApiFactory.get_country_for_candidate_backfill_use_case,
      add_country_id_from_address: add_country_use_case,
      assessments_country_id_gateway: Gateway::AssessmentsCountryIdGateway.new,
    )
  end

  include_context "when extracting the country"

  let!(:add_country_use_case) do
    UseCase::AddCountryIdFromAddress.new(Gateway::CountryGateway.new)
  end

  let(:assessments_ids) { "0000-0000-0000-0000-0001, 0000-0000-0000-0000-0000" }

  before(:all) do
    add_countries
    add_address_base uprn: "100020003000", postcode: "NP16 5UB", country_code: "W"
    add_address_base uprn: "100020004000", postcode: "SW1 0AA", country_code: "E"

    assessments = [
      {
        rrn: "0000-0000-0000-0000-0001",
        schema_type: "SAP-Schema-18.0.0",
        uprn: "RRN-0000-0000-0000-0000-0001",
        country_code: "WLS",
        postcode: "NP16 5UB",
      },
      {
        rrn: "0000-0000-0000-0000-0000",
        schema_type: "SAP-Schema-18.0.0",
        uprn: "RRN-0000-0000-0000-0000-0000",
        country_code: "ENG",
        postcode: "SW1 0AA",
      },
    ]
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
    assessments.each do |assessment|
      xml = assessment[:type].nil? ? (Nokogiri.XML Samples.xml assessment[:schema_type]) : (Nokogiri.XML Samples.xml assessment[:schema_type], assessment[:type])
      xml.at("//*[local-name() = 'RRN']").content = assessment[:rrn]
      xml.at("//*[local-name() = 'UPRN']").content = assessment[:uprn] if assessment[:uprn]
      xml.at("Registration-Date").content = assessment[:registered_date] if assessment[:registered_date]
      xml.at("//*[local-name() = 'Country-Code']").content = assessment[:country_code] if assessment[:country_code]
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
  end

  describe "#execute" do
    it "does not return an error" do
      expect { use_case.execute(assessments_ids:) }.not_to raise_error
    end

    context "when a SAP 18.0.0 assessment with WLS as the XML country code is updated from EAW" do
      let(:assessment_id) { "0000-0000-0000-0000-0001" }

      before do
        eaw_country_id = ActiveRecord::Base.connection.exec_query("SELECT country_id from countries WHERE country_code = 'EAW'").map { |rows| rows["country_id"] }.first
        update_eaw = <<-SQL
          UPDATE assessments_country_ids
          SET assessment_id = '#{assessment_id}', country_id = #{eaw_country_id}
          WHERE assessment_id = '#{assessment_id}'
        SQL
        ActiveRecord::Base.connection.exec_query(update_eaw, "SQL")
      end

      it "updates to Wales" do
        use_case.execute(assessments_ids:)
        expect(get_country_for_assessment(assessment_id:)).to eq "Wales"
      end
    end

    context "when a SAP 18.0.0 assessment with ENG as the XML country code is updated from UKN" do
      let(:assessment_id) { "0000-0000-0000-0000-0000" }

      before do
        ukn_country_id = ActiveRecord::Base.connection.exec_query("SELECT country_id from countries WHERE country_code = 'UKN'").map { |rows| rows["country_id"] }.first
        update_ukn = <<-SQL
          UPDATE assessments_country_ids
          SET assessment_id = '#{assessment_id}', country_id = #{ukn_country_id}
          WHERE assessment_id = '#{assessment_id}'
        SQL
        ActiveRecord::Base.connection.exec_query(update_ukn, "SQL")
      end

      it "updates to England" do
        use_case.execute(assessments_ids:)
        expect(get_country_for_assessment(assessment_id:)).to eq "England"
      end
    end
  end
end
