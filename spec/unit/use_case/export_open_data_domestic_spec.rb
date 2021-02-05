describe UseCase::ExportOpenDataDomestic do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      expected_rdsap_values = {
        rrn: "0000-0000-0000-0000-0000",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        building_reference_number: "UPRN-000000000000",
        address1: "1 Some Street",
        address2: "",
        address3: "",
        posttown: "Post-Town1",
        postcode: "A0 0AA",
        construction_age_band: "K",
        current_energy_rating: "e",
        potential_energy_rating: "e",
        current_energy_efficiency: "50",
        potential_energy_efficiency: "50",
        property_type: "Dwelling-Type0",
        tenure: "1",
        transaction_type: "1",
        environmental_impact_current: "50",
        environmental_impact_potential: "50",
        energy_consumption_current: "0",
        energy_consumption_potential: "0",
        co2_emissions_current: "2.4",
        co2_emiss_curr_per_floor_area: "0",
        co2_emissions_potential: "1.4",
        heating_cost_current: "365.98",
        heating_cost_potential: "250.34",
        hot_water_cost_current: "200.40",
        hot_water_cost_potential: "180.43",
        lighting_cost_current: "123.45",
        lighting_cost_potential: "84.23",
        total_floor_area: "1",
        mains_gas_flag: "Y",
        flat_top_storey: "N",
        flat_storey_count: "3",
        main_heating_controls: "Description9",
        multi_glaze_proportion: "100",
        glazed_area: "1",
        number_habitable_rooms: "5",
        number_heated_rooms: "5",
        low_energy_lighting: "100",
        fixed_lighting_outlets_count: "16",
        low_energy_fixed_lighting_outlets_count: "16",
        number_open_fireplaces: "0",
        hotwater_description: "Description11",
        hot_water_energy_eff: "N/A",
        hot_water_env_eff: "N/A",
        wind_turbine_count: "0",
        heat_loss_corridor: "2",
        unheated_corridor_length: "10",
        windows_description: "Description6",
        windows_energy_eff: "N/A",
        windows_env_eff: "N/A",
        secondheat_description: "Description13",
        sheating_energy_eff: "N/A",
        sheating_env_eff: "N/A",
        lighting_description: "Description12",
        lighting_energy_eff: "N/A",
        lighting_env_eff: "N/A",
        photo_supply: "0",
        built_form: "Semi-Detached",
        mainheat_description: "Description7, Description8",
        mainheat_energy_eff: "N/A",
        mainheat_env_eff: "N/A",
        extension_count: "0",
        report_type: "2",
        mainheatcont_description: "Description9, Description10",
        roof_description: "Description2, Description3",
        roof_energy_eff: "N/A, N/A",
        roof_env_eff: "N/A, N/A",
        walls_description: "Description0, Description1",
        walls_energy_eff: "N/A, N/A",
        walls_env_eff: "N/A, N/A",
        energy_tariff: "2",
        floor_level: "01",
        solar_water_heating_flag: "N",
        mechanical_ventilation: "0",
        floor_height: "2.45"
      }
      expected_sap_values = {
        rrn: "0000-0000-0000-0000-0000",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        building_reference_number: "UPRN-000000000000",
        address1: "1 Some Street",
        address2: "Some Area",
        address3: "Some County",
        posttown: "Post-Town1",
        postcode: "A0 0AA",
        construction_age_band: "1750",
        current_energy_rating: "e",
        potential_energy_rating: "e",
        current_energy_efficiency: "50",
        potential_energy_efficiency: "50",
        property_type: "Dwelling-Type0",
        tenure: "1",
        transaction_type: "1",
        environmental_impact_current: "50",
        environmental_impact_potential: "50",
        energy_consumption_current: "0",
        energy_consumption_potential: "0",
        co2_emissions_current: "2.4",
        co2_emiss_curr_per_floor_area: "0",
        co2_emissions_potential: "1.4",
        heating_cost_current: "365.98",
        heating_cost_potential: "250.34",
        hot_water_cost_current: "200.40",
        hot_water_cost_potential: "180.43",
        lighting_cost_current: "123.45",
        lighting_cost_potential: "84.23",
        total_floor_area: "10",
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
        mainheat_description: "Thermostat, Thermostat",
      }

      let(:rdsap_odc_hash) do
        expected_rdsap_values.merge(
          {
            rrn: "0000-0000-0000-0000-0000",
            lodgement_date: date_today,
          },
        )
      end
      let(:sap_odc_hash) do
        expected_sap_values.merge(
          {
            rrn: "0000-0000-0000-0000-1000",
            lodgement_date: date_today,
          },
        )
      end
      let(:exported_data) { described_class.new.execute }

      before(:all) do
        scheme_id = add_scheme_and_get_id
        domestic_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_assessment_id = domestic_xml.at("RRN")
        domestic_assessment_date = domestic_xml.at("Registration-Date")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")

        domestic_legacy_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-17.0")
        domestic_legacy_sap_assessment_id = domestic_legacy_sap_xml.at("RRN")
        domestic_legacy_sap_assessment_date = domestic_legacy_sap_xml.at("Registration-Date")

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")
        domestic_ni_sap_assessment_date = domestic_ni_sap_xml.at("Registration-Date")

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
        domestic_assessment_date.children = "2017-05-04"
        domestic_assessment_id.children = "0000-0000-0000-0000-0100"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_assessment_date.children = date_today
        domestic_assessment_id.children = "0000-0000-0000-0000-0000"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        # TODO: Add NI lodgement

        domestic_sap_assessment_date.children = date_today
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-1000"
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
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-17.0",
          override: true,
        )
     end

      it "expects the number of non Northern Irish RdSAP and SAP lodgements within required date range for ODC to be 2" do
        expect(exported_data.length).to eq(2)
      end

      expected_rdsap_values.keys
        .each do |key|
        it "returns the #{key} that matches the RdSAP test data for the equivalent entry in the ODC hash" do
          expect(exported_data[0][key.to_sym]).to include(rdsap_odc_hash[key])
        end
      end

      expected_sap_values.reject { |k| %i[flat_storey_count unheated_corridor_length mains_gas_flag heat_loss_corridor number_heated_rooms number_habitable_rooms photo_supply glazed_area].include? k }
        .keys
        .each do |key|
        it "returns the #{key} that matches the SAP test data for the equivalent entry in the ODC hash" do
          expect(exported_data[1][key.to_sym]).to include(sap_odc_hash[key])
        end
      end
    end
  end
end
