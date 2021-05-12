describe UseCase::ExportOpenDataDomestic, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:export_object) { described_class.new }

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
        current_energy_efficiency: "50",
        potential_energy_efficiency: "72",
        property_type: "House",
        tenure: "Owner-occupied",
        transaction_type: "marketed sale",
        environment_impact_current: "52",
        environment_impact_potential: "74",
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
        flat_storey_count: "3",
        multi_glaze_proportion: "100",
        glazed_area: "Normal",
        number_habitable_rooms: "5",
        number_heated_rooms: "5",
        low_energy_lighting: "100",
        fixed_lighting_outlets_count: "16",
        low_energy_fixed_lighting_outlets_count: "16",
        number_open_fireplaces: "0",
        hotwater_description: "From main system",
        hot_water_energy_eff: "Good",
        hot_water_env_eff: "Good",
        wind_turbine_count: "0",
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
        extension_count: "0",
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
        current_energy_efficiency: "50",
        potential_energy_efficiency: "72",
        property_type: "Maisonette",
        tenure: "Owner-occupied",
        transaction_type: "marketed sale",
        environment_impact_current: "52",
        environment_impact_potential: "74",
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
        fixed_lighting_outlets_count: "8",
        low_energy_fixed_lighting_outlets_count: "8",
        number_open_fireplaces: "0",
        hotwater_description: "Gas boiler",
        hot_water_energy_eff: "N/A",
        hot_water_env_eff: "N/A",
        wind_turbine_count: "0",
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

      before(:all) do
        add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
        add_outcodes("A0", 51.5045, 0.4865, "London")

        scheme_id = add_scheme_and_get_id
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_assessment_id = domestic_rdsap_xml.at("RRN")
        domestic_rdsap_assessment_date =
          domestic_rdsap_xml.at("Registration-Date")
        domestic_rdsap_building_reference_number = domestic_rdsap_xml.at("UPRN")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")
        domestic_sap_building_reference_number = domestic_sap_xml.at("UPRN")

        domestic_legacy_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-17.0")
        domestic_legacy_sap_assessment_id = domestic_legacy_sap_xml.at("RRN")
        domestic_legacy_sap_assessment_date =
          domestic_legacy_sap_xml.at("Registration-Date")

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")
        domestic_ni_sap_assessment_date =
          domestic_ni_sap_xml.at("Registration-Date")
        domestic_ni_sap_postcode =
          domestic_ni_sap_xml.at("Property Address Postcode")

        add_assessor(
          scheme_id,
          "SPEC000000",
          AssessorStub.new.fetch_request_body(
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
            nonDomesticDec: "ACTIVE",
            domesticRdSap: "ACTIVE",
            domesticSap: "ACTIVE",
            nonDomesticSp3: "ACTIVE",
            nonDomesticCc4: "ACTIVE",
            gda: "ACTIVE",
          ),
        )
        domestic_rdsap_assessment_date.children = "2017-05-04"
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0100"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_rdsap_assessment_date.children = date_today
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0000"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_rdsap_assessment_date.children = date_today
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0023"
        domestic_rdsap_building_reference_number.children =
          "RRN-0000-0000-0000-0000-0023"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_sap_assessment_date.children = date_today
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-1000"
        property_type_node = domestic_sap_xml.at("Property-Type")
        property_type_node.children = "3"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        domestic_sap_assessment_date.children = date_today
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-0033"
        domestic_sap_building_reference_number.children =
          "RRN-0000-0000-0000-0000-0033"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        domestic_legacy_sap_assessment_date.children = "2017-05-04"
        domestic_legacy_sap_assessment_id.children = "0000-0000-0000-0000-1010"
        lodge_assessment(
          assessment_body: domestic_legacy_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-17.0",
          override: true,
        )

        domestic_ni_sap_assessment_id.children = "0000-0000-0040-0000-1010"
        domestic_ni_sap_assessment_date.children = date_today
        domestic_ni_sap_postcode.children = "BT4 3NE"
        lodge_assessment(
          assessment_body: domestic_ni_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-NI-18.0.0",
          override: true,
        )
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

      it "expects the number of non Northern Irish RdSAP and SAP lodgements within required date range for ODC to be 4" do
        expect(exported_data.length).to eq(4)
      end

      expected_rdsap_values.reject { |k|
        %i[lodgement_datetime].include? k
      }.keys.each do |key|
        it "returns the #{key} that matches the RdSAP test data for the equivalent entry in the ODC hash" do
          expect(rdsap_assessment[key.to_sym]).to eq(rdsap_odc_hash[key])
        end
      end

      it "expects the RdSAP assessment's lodged date time to be now based on a frozen time " do
        expect(DateTime.parse(rdsap_assessment[:lodgement_datetime])).to eq(
          Time.now,
        )
      end

      it "expects the SAP assessment's lodged date time to be now based on a frozen time " do
        expect(DateTime.parse(sap_assessment[:lodgement_datetime])).to eq(
          Time.now,
        )
      end

      it "returns a hash with building_reference_number nil when an RdSAP is submitted when building_reference_number is not a UPRN" do
        expect(rdsap_assessment_with_rrn_building_ref).to eq(nil)
      end

      it "contains the expected keys for RdSAP" do
        expect(exported_data[0].keys - rdsap_odc_hash.keys).to be_empty
      end

      expected_sap_values.reject { |k|
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
        ].include? k
      }.keys.each do |key|
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

      it "returns 4 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(4)
        expect(export_object.execute("2019-07-01", 2).length).to eq(4)
      end

      it "returns 4 row when no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(4)
        expect(statistics.first["num_rows"]).to eq(4)
      end

      it "returns 0 when called again with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(4)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end
    end
  end
end
