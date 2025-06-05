describe UseCase::ExportOpenDataDomestic, :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  require_relative "../../shared_context/shared_lodgement"
  include_context "when lodging XML"

  context "when creating the open data reporting release" do
    let(:date) do
      Time.utc(2021, 6, 21).strftime("%F")
    end
    let(:date_time) do
      Time.utc(2021, 6, 21).strftime("%F %H:%M:%S")
    end
    let(:export_object) { described_class.new }
    let(:rdsap_odc_hash) do
      expected_rdsap_values.merge(
        { lodgement_date: date, lodgement_datetime: date_time },
      )
    end
    let(:sap_odc_hash) do
      expected_sap_values.merge(
        { lodgement_date: date, lodgement_datetime: date_time, mechanical_ventilation: nil, extension_count: nil },
      )
    end
    let(:exported_data) do
      described_class
        .new
        .execute("2019-07-01", 2)
        .sort_by! { |key| key[:assessment_id] }
    end
    let(:statistics) do
      gateway = Gateway::OpenDataLogGateway.new
      gateway.fetch_log_statistics
    end
    let(:rdsap_assessment) do
      expected_data_hash =
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"
        end
      expected_data_hash.first
    end
    let(:sap_assessment) do
      expected_data_hash =
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996"
        end
      expected_data_hash.first
    end
    let(:rdsap_assessment_with_rrn_building_ref) do
      expected_data_hash =
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "46cd39a5a7ccc7e4abab6e99577831f3c6dff2ce98bea5858195063694967ff4"
        end
      expected_data_hash.first[:building_reference_number]
    end
    let(:sap_assessment_with_rrn_building_ref) do
      expected_data_hash =
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "c721f7c21520e8dc97d9746d0747c285d057971acee9e2ef3b8d94f8d7a1ed43"
        end
      expected_data_hash.first[:building_reference_number]
    end
    let(:rdsap_21_assessment) do
      expected_data_hash =
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "5b151ee72cc5503688f48e56ff32df4d1205655413e327bf3a071a081d23750c"
        end
      expected_data_hash.first
    end

    before(:all) do
      add_countries
      add_postcodes("SW1A 2AA", 51.5045, 0.0865, "London")

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

    context "when exporting domestic certificates and reports" do
      let(:rejected_keys) do
        %i[
          lodgement_datetime
          flat_storey_count
          unheated_corridor_length
          mains_gas_flag
          heat_loss_corridor
          number_heated_rooms
          number_habitable_rooms
          photo_supply
          glazed_area
          extension_count
          solar_water_heating_flag
          mechanical_ventilation
        ]
      end

      after do
        Timecop.return
      end

      it "expects the number of non Northern Irish RdSAP and SAP lodgements within required create_at date range for ODC to be 5" do
        expect(exported_data.length).to eq(5)
      end

      it "returns the expected RdSAP values" do
        expect(rdsap_assessment).to eq rdsap_odc_hash
      end

      it "returns a hash with building_reference_number nil when an RdSAP is submitted when building_reference_number is not a UPRN" do
        expect(rdsap_assessment_with_rrn_building_ref).to be_nil
      end

      it "contains the expected keys for RdSAP" do
        expect((rdsap_assessment.keys - rdsap_odc_hash.keys) | (rdsap_odc_hash.keys - rdsap_assessment.keys)).to be_empty
      end

      it "returns the expected SAP values" do
        expect(sap_assessment).to eq sap_odc_hash
      end

      it "returns a hash with building_reference_number nil when a SAP is submitted when building_reference_number is not a UPRN" do
        expect(sap_assessment_with_rrn_building_ref).to be_nil
      end

      it "contains the expected keys for SAP" do
        expect((sap_assessment.keys - sap_odc_hash.keys) | (sap_odc_hash.keys - sap_assessment.keys)).to be_empty
      end

      it "returns 5 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 2).length).to eq(5)
      end

      it "returns 5 row when no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(5)
        expect(statistics.first["num_rows"]).to eq(5)
      end

      it "returns 0 when called again with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end

      it "returns the correct values for rdsSAP 21.0.0" do
        hash_rrn = "5b151ee72cc5503688f48e56ff32df4d1205655413e327bf3a071a081d23750c"
        rdsap21_expectation = rdsap_odc_hash
        rdsap21_expectation[:assessment_id] = hash_rrn
        rdsap21_expectation[:inspection_date] = "2023-12-01"
        rdsap21_expectation[:lodgement_datetime] = date_time
        rdsap21_expectation[:construction_age_band] = "England and Wales: 2022 onwards"
        rdsap21_expectation[:transaction_type] = "Non-grant scheme (e.g. MEES)"
        rdsap21_expectation[:glazed_area] = nil
        rdsap21_expectation[:glazed_type] = nil
        rdsap21_expectation[:low_energy_lighting] = 100
        rdsap21_expectation[:fixed_lighting_outlets_count] = 31
        rdsap21_expectation[:low_energy_fixed_lighting_outlets_count] = 31
        rdsap21_expectation[:number_open_fireplaces] = nil
        rdsap21_expectation[:mechanical_ventilation] = "positive input from outside"

        expect(rdsap_21_assessment).to eq rdsap21_expectation
      end
    end
  end
end
