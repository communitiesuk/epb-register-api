describe UseCase::ExportOpenDataDomesticByHashedId, :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  require_relative "../../shared_context/shared_lodgement"
  include_context "when lodging XML"

  context "when creating the open data reporting release" do
    let(:rdsap_odc_hash) do
      expected_rdsap_values.merge(
        { lodgement_date: date_today, lodgement_datetime: datetime_today },
      )
    end

    let(:exported_data) do
      described_class.new.execute(%w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996])
    end
    let(:statistics) do
      gateway = Gateway::OpenDataLogGateway.new
      gateway.fetch_log_statistics
    end

    before(:all) do
      # Timecop.freeze(2020, 5, 5, 0, 0, 0)
      add_countries
      add_postcodes("SW1A 2AA", 51.5045, 0.0865, "London")
      add_outcodes("SW1A", 51.5045, 0.4865, "London")
      scheme_id = add_assessor_helper
      lodge_epc_helper(scheme_id:, schema: "RdSAP-Schema-20.0.0", rrn: "0000-0000-0000-0000-0100", assessment_date: "2017-05-04")
      lodge_epc_helper(scheme_id:, schema: "RdSAP-Schema-20.0.0", rrn: "0000-0000-0000-0000-0000", assessment_date: date_today)
      lodge_epc_helper(scheme_id:, schema: "RdSAP-Schema-20.0.0", rrn: "0000-0000-0000-0000-0023", assessment_date: date_today, uprn: "RRN-0000-0000-0000-0000-0023")
      lodge_epc_helper(scheme_id:, schema: "SAP-Schema-18.0.0", rrn: "0000-0000-0000-0000-1000", assessment_date: date_today, property_type: "3")
      lodge_epc_helper(scheme_id:, schema: "SAP-Schema-18.0.0", rrn: "0000-0000-0000-0000-0033", assessment_date: date_today, uprn: "RRN-0000-0000-0000-0000-0033", property_type: "3")
      lodge_epc_helper(scheme_id:, schema: "SAP-Schema-17.0", rrn: "0000-0000-0000-0000-1010", assessment_date: "2017-05-04", override: true)
      lodge_epc_helper(scheme_id:, schema: "SAP-Schema-NI-18.0.0", rrn: "0000-0000-0000-0000-1010", assessment_date: date_today, postcode: "BT4 3NE")

      lodge_epc_helper(scheme_id:, schema: "RdSAP-Schema-21.0.0", rrn: "0000-0000-0000-0000-1019", assessment_date: date_today)
      # created_at is now being used instead of date_registered for the date boundaries
      # updated_created_at
      updated_created_at

      Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.update_all country_id: 1
      Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.update("0000-0000-0000-0000-1010", country_id: 4)
    end

    after do
      Timecop.return
    end

    context "when exporting domestic certificates using hashed assessment ids" do
      before do
        Timecop.freeze(2021, 6, 21, 0, 0, 0)
      end

      after do
        Timecop.return
      end

      it "returns 2 certificates worth of data when called" do
        expect(exported_data.length).to eq(2)
      end

      it "returns the correct data", :aggregate_failures do
        exported_assessment = exported_data.select { |assessment| assessment[:assessment_id] == "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a" }
        expect(exported_assessment.first.to_a - rdsap_odc_hash.to_a).to eq []
      end
    end
  end
end
