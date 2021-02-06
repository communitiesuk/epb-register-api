require_relative "xml_view_test_helper"

describe ViewModel::RdSapWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "RdSAP-Schema-20.0.0",
        },
        {
          schema: "RdSAP-Schema-19.0",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-18.0",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-17.1",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-17.0",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-NI-20.0.0",
        },
        {
          schema: "RdSAP-Schema-NI-19.0",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-NI-18.0",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-NI-17.4",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
        {
          schema: "RdSAP-Schema-NI-17.3",
          different_buried_fields: {
            address: {
              address_id: "LPRN-0000000000",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        type_of_assessment: "RdSAP",
        assessment_id: "0000-0000-0000-0000-0000",
        date_of_expiry: "2030-05-03",
        date_of_assessment: "2020-05-04",
        date_of_registration: "2020-05-04",
        date_registered: "2020-05-04",
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Post-Town1",
        postcode: "A0 0AA",
        address: {
          address_id: "UPRN-000000000000",
          address_line1: "1 Some Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "Name0",
          contact_details: {
            email: "a@b.c",
            telephone: "0921-19037",
          },
        },
        current_carbon_emission: 2.4,
        current_energy_efficiency_band: "e",
        current_energy_efficiency_rating: 50,
        dwelling_type: "Dwelling-Type0",
        estimated_energy_cost: "689.83",
        main_fuel_type: "26",
        heat_demand: {
          current_space_heating_demand: 30,
          current_water_heating_demand: 60,
          impact_of_cavity_insulation: -12,
          impact_of_loft_insulation: -8,
          impact_of_solid_wall_insulation: -16,
        },
        heating_cost_current: "365.98",
        heating_cost_potential: "250.34",
        hot_water_cost_current: "200.40",
        hot_water_cost_potential: "180.43",
        lighting_cost_current: "123.45",
        lighting_cost_potential: "84.23",
        potential_carbon_emission: 1.4,
        potential_energy_efficiency_band: "e",
        potential_energy_efficiency_rating: 50,
        potential_energy_saving: "174.83",
        primary_energy_use: "0",
        energy_consumption_potential: "0",
        property_age_band: "K",
        property_summary: [
          {
            description: "Description0",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "wall",
          },
          {
            description: "Description1",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "wall",
          },
          {
            description: "Description2",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "roof",
          },
          {
            description: "Description3",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "roof",
          },
          {
            description: "Description4",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "floor",
          },
          {
            description: "Description5",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "floor",
          },
          {
            description: "Description6",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "window",
          },
          {
            description: "Description7",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating",
          },
          {
            description: "Description8",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating",
          },
          {
            description: "Description9",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating_controls",
          },
          {
            description: "Description10",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating_controls",
          },
          {
            description: "Description11",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "hot_water",
          },
          {
            description: "Description12",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "lighting",
          },
          {
            description: "Description13",
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "secondary_heating",
          },
        ],
        recommended_improvements: [
          {
            energy_performance_rating_improvement: 50,
            energy_performance_band_improvement: "e",
            environmental_impact_rating_improvement: 50,
            green_deal_category_code: "1",
            improvement_category: "6",
            improvement_code: "5",
            improvement_description: nil,
            improvement_title: nil,
            improvement_type: "Z3",
            indicative_cost: "£100 - £350",
            sequence: 0,
            typical_saving: "0.0",
          },
          {
            energy_performance_rating_improvement: 60,
            energy_performance_band_improvement: "d",
            environmental_impact_rating_improvement: 64,
            green_deal_category_code: "3",
            improvement_category: "2",
            improvement_code: "1",
            improvement_description: nil,
            improvement_title: nil,
            improvement_type: "Z2",
            indicative_cost: "2",
            sequence: 1,
            typical_saving: "0.1",
          },
        ],
        related_party_disclosure_number: nil,
        related_party_disclosure_text: "Related-Party-Disclosure-Text0",
        tenure: "1",
        transaction_type: "1",
        total_floor_area: 1.0,
        status: "ENTERED",
        environmental_impact_current: "50",
      }
    end

    it "read the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  context "when calling to_report" do
    let(:schemas) do
      [
        {
          schema: "RdSAP-Schema-20.0.0",
        },
        {
          schema: "RdSAP-Schema-19.0",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-18.0",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-17.1",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-17.0",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-NI-20.0.0",
        },
        {
          schema: "RdSAP-Schema-NI-19.0",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-NI-18.0",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-NI-17.4",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
        {
          schema: "RdSAP-Schema-NI-17.3",
          different_fields: {
            building_reference_number: "LPRN-0000000000",
          },
        },
      ]
    end

    let(:assertion) do
      {
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
        energy_tariff: "off-peak 7 hour",
        floor_level: "01",
        solar_water_heating_flag: "N",
        mechanical_ventilation: "0",
        floor_height: "2.45"
      }
    end

    it "should read the appropriate values" do
      test_xml_doc(schemas, assertion, :to_report)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::RdSapWrapper.new "", "invalid"
    }.to raise_error(ArgumentError).with_message "Unsupported schema type"
  end
end
