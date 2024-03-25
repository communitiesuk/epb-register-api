describe UseCase::ExportOpenDataDomestic, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin
  require_relative "../../shared_context/shared_logdement"
  include_context "when lodging XML"

  context "when creating the open data reporting release" do
    expected_rdsap_values = {
      assessment_id:
        "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
      inspection_date: "2020-05-04",
      lodgement_date: "2020-05-04",
      lodgement_datetime: "2021-02-18 00:00:00",
      building_reference_number: "UPRN-000000000000",
      address1: "1 Some Street",
      address2: "",
      address3: "",
      posttown: "Whitbury",
      postcode: "A0 0AA",
      construction_age_band: "England and Wales: 2007-2011",
      current_energy_rating: "e",
      potential_energy_rating: "c",
      current_energy_efficiency: 50,
      potential_energy_efficiency: 72,
      property_type: "House",
      tenure: "Owner-occupied",
      transaction_type: "marketed sale",
      environment_impact_current: 52,
      environment_impact_potential: 74,
      energy_consumption_current: "230",
      energy_consumption_potential: "88",
      co2_emissions_current: "2.4",
      co2_emiss_curr_per_floor_area: "20",
      co2_emissions_potential: "1.4",
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      total_floor_area: "55",
      mains_gas_flag: "Y",
      flat_top_storey: "N",
      flat_storey_count: 3,
      multi_glaze_proportion: "100",
      glazed_area: "Normal",
      number_habitable_rooms: 5,
      number_heated_rooms: 5,
      low_energy_lighting: "100",
      fixed_lighting_outlets_count: 16,
      low_energy_fixed_lighting_outlets_count: 16,
      number_open_fireplaces: 0,
      hotwater_description: "From main system",
      hot_water_energy_eff: "Good",
      hot_water_env_eff: "Good",
      wind_turbine_count: 0,
      heat_loss_corridor: "unheated corridor",
      unheated_corridor_length: "10",
      windows_description: "Fully double glazed",
      windows_energy_eff: "Average",
      windows_env_eff: "Average",
      secondheat_description: "Room heaters, electric",
      sheating_energy_eff: "N/A",
      sheating_env_eff: "N/A",
      lighting_description: "Low energy lighting in 50% of fixed outlets",
      lighting_energy_eff: "Good",
      lighting_env_eff: "Good",
      photo_supply: "0",
      built_form: "Semi-Detached",
      mainheat_description:
        "Boiler and radiators, anthracite, Boiler and radiators, mains gas",
      mainheat_energy_eff: "Average",
      mainheat_env_eff: "Very Poor",
      extension_count: 0,
      report_type: "2",
      mainheatcont_description: "Programmer, room thermostat and TRVs",
      roof_description: "Pitched, 25 mm loft insulation",
      roof_energy_eff: "Poor",
      roof_env_eff: "Poor",
      walls_description: "Solid brick, as built, no insulation (assumed)",
      walls_energy_eff: "Very Poor",
      walls_env_eff: "Very Poor",
      energy_tariff: "Single",
      floor_level: "01",
      solar_water_heating_flag: "N",
      mechanical_ventilation: "natural",
      floor_height: "2.45",
      main_fuel: "mains gas (not community)",
      floor_description: "Suspended, no insulation (assumed)",
      floor_energy_eff: "N/A",
      floor_env_eff: "N/A",
      mainheatc_energy_eff: "Good",
      mainheatc_env_eff: "Good",
      glazed_type: "double glazing installed during or after 2002",
      region: "London",
    }
    expected_sap_values = {
      assessment_id:
        "a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996",
      inspection_date: "2020-05-04",
      lodgement_date: "2020-05-04",
      lodgement_datetime: "2021-02-18 00:00:00",
      building_reference_number: "UPRN-000000000000",
      address1: "1 Some Street",
      address2: "Some Area",
      address3: "Some County",
      posttown: "Whitbury",
      postcode: "A0 0AA",
      construction_age_band: "1750",
      current_energy_rating: "e",
      potential_energy_rating: "c",
      current_energy_efficiency: 50,
      potential_energy_efficiency: 72,
      property_type: "Maisonette",
      tenure: "Owner-occupied",
      transaction_type: "marketed sale",
      environment_impact_current: 52,
      environment_impact_potential: 74,
      energy_consumption_current: "230",
      energy_consumption_potential: "88",
      co2_emissions_current: "2.4",
      co2_emiss_curr_per_floor_area: "20",
      co2_emissions_potential: "1.4",
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      total_floor_area: "69",
      mains_gas_flag: nil,
      flat_top_storey: "N",
      flat_storey_count: nil,
      multi_glaze_proportion: "50",
      glazed_area: nil,
      number_habitable_rooms: nil,
      number_heated_rooms: nil,
      low_energy_lighting: "100",
      fixed_lighting_outlets_count: 8,
      low_energy_fixed_lighting_outlets_count: 8,
      number_open_fireplaces: 0,
      hotwater_description: "Gas boiler",
      hot_water_energy_eff: "N/A",
      hot_water_env_eff: "N/A",
      wind_turbine_count: 0,
      heat_loss_corridor: nil,
      unheated_corridor_length: nil,
      windows_description: "Glass window",
      windows_energy_eff: "N/A",
      windows_env_eff: "N/A",
      secondheat_description: "Electric heater",
      sheating_energy_eff: "N/A",
      sheating_env_eff: "N/A",
      lighting_description: "Energy saving bulbs",
      lighting_energy_eff: "N/A",
      lighting_env_eff: "N/A",
      photo_supply: nil,
      built_form: "Detached",
      mainheat_description: "Gas boiler, Gas boiler",
      report_type: "3",
      mainheatcont_description: "Thermostat",
      roof_description: "Slate roof",
      roof_energy_eff: "N/A",
      roof_env_eff: "N/A",
      walls_description: "Brick walls",
      walls_energy_eff: "N/A",
      walls_env_eff: "N/A",
      energy_tariff: "standard tariff",
      floor_level: "1",
      mainheat_energy_eff: "N/A",
      mainheat_env_eff: "N/A",
      extension_count: 0,
      solar_water_heating_flag: nil,
      mechanical_ventilation: "natural",
      floor_height: "2.4",
      main_fuel: "Electricity: electricity sold to grid",
      floor_description: "Tiled floor",
      floor_energy_eff: "N/A",
      floor_env_eff: "N/A",
      mainheatc_energy_eff: "N/A",
      mainheatc_env_eff: "N/A",
      glazed_type: nil,
      region: "London",
    }

    let(:export_object) { described_class.new }
    let(:rdsap_odc_hash) do
      expected_rdsap_values.merge(
        { lodgement_date: date_today, lodgement_datetime: datetime_today },
      )
    end
    let(:sap_odc_hash) do
      expected_sap_values.merge(
        { lodgement_date: date_today, lodgement_datetime: datetime_today },
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

    before(:all) do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
      add_outcodes("A0", 51.5045, 0.4865, "London")
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
      ActiveRecord::Base
        .connection.execute "UPDATE assessments SET created_at = '2017-05-04 00:00:00.000000' WHERE  assessment_id IN ('0000-0000-0000-0000-1010', '0000-0000-0000-0000-0100')"
    end

    context "when exporting domestic certificates and reports" do
      it "expects the number of non Northern Irish RdSAP and SAP lodgements within required create_at date range for ODC to be 5" do
        expect(exported_data.length).to eq(5)
      end

      expected_rdsap_values.reject { |k| k == :lodgement_datetime }.each_key do |key|
        it "returns the #{key} that matches the RdSAP test data for the equivalent entry in the ODC hash" do
          expect(rdsap_assessment[key.to_sym]).to eq(rdsap_odc_hash[key])
        end
      end

      it "expects the RdSAP assessment's lodged date time to be now based on a frozen time" do
        expect(Time.find_zone("UTC").parse(rdsap_assessment[:lodgement_datetime])).to eq(
          Time.now,
        )
      end

      it "expects the SAP assessment's lodged date time to be now based on a frozen time" do
        expect(Time.find_zone("UTC").parse(sap_assessment[:lodgement_datetime])).to eq(
          Time.now,
        )
      end

      it "returns a hash with building_reference_number nil when an RdSAP is submitted when building_reference_number is not a UPRN" do
        expect(rdsap_assessment_with_rrn_building_ref).to eq(nil)
      end

      it "contains the expected keys for RdSAP" do
        expect(exported_data[0].keys - rdsap_odc_hash.keys).to be_empty
      end

      rejected_keys = %i[
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

      expected_sap_values.reject { |k| rejected_keys.include? k }.each_key do |key|
        it "returns the #{key} that matches the SAP test data for the equivalent entry in the ODC hash" do
          expect(sap_assessment[key.to_sym]).to eq(sap_odc_hash[key])
        end
      end

      it "returns a hash with building_reference_number nil when a SAP is submitted when building_reference_number is not a UPRN" do
        expect(sap_assessment_with_rrn_building_ref).to eq(nil)
      end

      it "contains the expected keys for SAP" do
        expect(exported_data[1].keys - sap_odc_hash.keys).to be_empty
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
        rdsap21 = exported_data.find { |key| key[:assessment_id] == hash_rrn }
        rdsap21_expectation = rdsap_odc_hash
        rdsap21_expectation[:assessment_id] = hash_rrn
        rdsap21_expectation[:inspection_date] = "2023-12-01"
        rdsap21_expectation[:lodgement_datetime] = "2021-06-21 00:00:00"
        rdsap21_expectation[:construction_age_band] = "England and Wales: 2022 onwards"
        rdsap21_expectation[:transaction_type] = "Non-grant scheme (e.g. MEES)"
        rdsap21_expectation[:glazed_area] = nil
        rdsap21_expectation[:glazed_type] = nil
        rdsap21_expectation[:low_energy_lighting] = nil
        rdsap21_expectation[:fixed_lighting_outlets_count] = nil
        rdsap21_expectation[:low_energy_fixed_lighting_outlets_count] = nil
        rdsap21_expectation[:number_open_fireplaces] = nil
        rdsap21_expectation[:mechanical_ventilation] = "positive input from outside"
        expect(rdsap21.to_a - rdsap21_expectation.to_a).to eq []
      end
    end

    context "when exporting domestic certificates using hashed assessment ids" do
      let(:exported_data) do
        described_class.new.execute_using_hashed_assessment_id(%w[4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996])
      end

      it "returns 2 certificates worth of data when called" do
        expect(exported_data.length).to eq(2)
      end

      it "returns the correct data" do
        exported_assessment = exported_data.select { |assessment| assessment[:assessment_id] == "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a" }
        rdsap_odc_hash[:lodgement_datetime] = "2021-06-21 00:00:00"
        expect(exported_assessment.first).to eq(rdsap_odc_hash)
      end
    end
  end
end
