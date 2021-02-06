require_relative "xml_view_test_helper"

describe ViewModel::SapWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      shared_difference_14 = {
        different_fields: {
          recommended_improvements: [
            {
              energy_performance_band_improvement: "e",
              energy_performance_rating_improvement: 50,
              environmental_impact_rating_improvement: 50,
              green_deal_category_code: nil,
              improvement_category: "1",
              improvement_code: "5",
              improvement_description: nil,
              improvement_title: nil,
              improvement_type: "A",
              indicative_cost: nil,
              sequence: 0,
              typical_saving: "0.0",
            },
            {
              energy_performance_band_improvement: "d",
              energy_performance_rating_improvement: 60,
              environmental_impact_rating_improvement: 64,
              green_deal_category_code: nil,
              improvement_category: "2",
              improvement_code: "1",
              improvement_description: nil,
              improvement_title: nil,
              improvement_type: "B",
              indicative_cost: nil,
              sequence: 1,
              typical_saving: "0.1",
            },
          ],
          property_summary: [
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "walls",
              description: "Brick walls",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "walls",
              description: "Brick walls",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "roof",
              description: "Slate roof",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "roof",
              description: "slate roof",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "floor",
              description: "Tiled floor",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "floor",
              description: "Tiled floor",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "windows",
              description: "Glass window",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating",
              description: "Gas boiler",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating_controls",
              description: "Thermostat",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "secondary_heating",
              description: "Electric heater",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "hot_water",
              description: "Gas boiler",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "lighting",
              description: "Energy saving bulbs",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "air_tightness",
              description: "Draft Exclusion",
            },
          ],
        },
        different_buried_fields: {
          heat_demand: {
            current_space_heating_demand: nil,
            current_water_heating_demand: nil,
            impact_of_cavity_insulation: nil,
            impact_of_loft_insulation: nil,
            impact_of_solid_wall_insulation: nil,
          },
        },
      }

      ni_difference = {
        different_fields: {
          recommended_improvements: [
            {
              energy_performance_band_improvement: "e",
              energy_performance_rating_improvement: 50,
              environmental_impact_rating_improvement: 50,
              green_deal_category_code: nil,
              improvement_category: "1",
              improvement_code: "5",
              improvement_description: nil,
              improvement_title: nil,
              improvement_type: "A",
              indicative_cost: "5",
              sequence: 0,
              typical_saving: "0.0",
            },
            {
              energy_performance_band_improvement: "d",
              energy_performance_rating_improvement: 60,
              environmental_impact_rating_improvement: 64,
              green_deal_category_code: nil,
              improvement_category: "2",
              improvement_code: "1",
              improvement_description: nil,
              improvement_title: nil,
              improvement_type: "B",
              indicative_cost: "2",
              sequence: 1,
              typical_saving: "0.1",
            },
          ],
        },
        different_buried_fields: {
          heat_demand: {
            impact_of_cavity_insulation: nil,
            impact_of_loft_insulation: nil,
            impact_of_solid_wall_insulation: nil,
          },
        },
      }

      ni_pre_17_difference = {
        different_buried_fields: {
          heat_demand: {
            current_space_heating_demand: nil,
            current_water_heating_demand: nil,
            impact_of_cavity_insulation: nil,
            impact_of_loft_insulation: nil,
            impact_of_solid_wall_insulation: nil,
          },
        },
        different_fields: {
          property_age_band: "D",
          property_summary: [
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "wall",
              description: "Brick walls",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "wall",
              description: "Brick walls",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "roof",
              description: "Slate roof",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "roof",
              description: "slate roof",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "floor",
              description: "Tiled floor",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "floor",
              description: "Tiled floor",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "window",
              description: "Glass window",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating",
              description: "Gas boiler",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating",
              description: "Gas boiler",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating_controls",
              description: "Thermostat",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "main_heating_controls",
              description: "Thermostat",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "hot_water",
              description: "Gas boiler",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "lighting",
              description: "Energy saving bulbs",
            },
            {
              energy_efficiency_rating: 0,
              environmental_efficiency_rating: 0,
              name: "secondary_heating",
              description: "Electric heater",
            },
          ],
        }.merge(ni_difference[:different_fields]),
      }

      [
        {
          schema: "SAP-Schema-18.0.0",
          different_fields: {
            address_id: "UPRN-000000000000",
          },
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          },
        },
        {
          schema: "SAP-Schema-NI-18.0.0",
          different_fields: {
            address_id: "UPRN-000000000000",
          }.merge(ni_difference[:different_fields]),
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000000",
            },
          }.merge(ni_difference[:different_buried_fields]),
        },
        { schema: "SAP-Schema-NI-17.4" }.merge(ni_difference),
        { schema: "SAP-Schema-NI-17.3" }.merge(ni_difference),
        { schema: "SAP-Schema-NI-17.2" }.merge(ni_difference),
        { schema: "SAP-Schema-17.1" },
        { schema: "SAP-Schema-NI-17.1" }.merge(ni_difference),
        { schema: "SAP-Schema-17.0" },
        { schema: "SAP-Schema-NI-17.0" }.merge(ni_difference),
        {
          schema: "SAP-Schema-16.3",
          type: "sap",
          unsupported_fields: %i[tenure],
        },
        {
          schema: "SAP-Schema-NI-16.1",
        }.merge(ni_pre_17_difference),
        {
          schema: "SAP-Schema-16.2",
          type: "sap",
          unsupported_fields: %i[tenure],
        },
        {
          schema: "SAP-Schema-16.1",
          type: "sap",
          unsupported_fields: %i[tenure],
        },
        {
          schema: "SAP-Schema-16.0",
          type: "sap",
          unsupported_fields: %i[tenure],
        },
        {
          schema: "SAP-Schema-15.0",
          type: "sap",
          unsupported_fields: %i[tenure],
          different_fields: {
            recommended_improvements: [
              {
                energy_performance_band_improvement: "e",
                energy_performance_rating_improvement: 50,
                environmental_impact_rating_improvement: 50,
                green_deal_category_code: nil,
                improvement_category: "1",
                improvement_code: "5",
                improvement_description: nil,
                improvement_title: nil,
                improvement_type: "A",
                indicative_cost: "5",
                sequence: 0,
                typical_saving: "0.0",
              },
              {
                energy_performance_band_improvement: "d",
                energy_performance_rating_improvement: 60,
                environmental_impact_rating_improvement: 64,
                green_deal_category_code: nil,
                improvement_category: "2",
                improvement_code: "1",
                improvement_description: nil,
                improvement_title: nil,
                improvement_type: "B",
                indicative_cost: "2",
                sequence: 1,
                typical_saving: "0.1",
              },
            ],
          },
          different_buried_fields: {
            heat_demand: {
              impact_of_cavity_insulation: nil,
              impact_of_loft_insulation: nil,
              impact_of_solid_wall_insulation: nil,
            },
          },
        },
        {
          schema: "SAP-Schema-14.1",
          type: "sap",
          unsupported_fields: %i[tenure],
        }.merge(shared_difference_14),
        {
          schema: "SAP-Schema-14.0",
          type: "sap",
          unsupported_fields: %i[tenure],
        }.merge(shared_difference_14),
      ]
    end

    let(:assertion) do
      {
        type_of_assessment: "SAP",
        assessment_id: "0000-0000-0000-0000-0000",
        date_of_expiry: "2030-05-03",
        date_of_assessment: "2020-05-04",
        date_of_registration: "2020-05-04",
        date_registered: "2020-05-04",
        address_id: "LPRN-0000000000",
        address_line1: "1 Some Street",
        address_line2: "Some Area",
        address_line3: "Some County",
        address_line4: nil,
        town: "Post-Town1",
        postcode: "A0 0AA",
        address: {
          address_id: "LPRN-0000000000",
          address_line1: "1 Some Street",
          address_line2: "Some Area",
          address_line3: "Some County",
          address_line4: nil,
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "Mr Test Boi TST",
          contact_details: {
            email: "a@b.c",
            telephone: "111222333",
          },
        },
        current_carbon_emission: 2.4,
        current_energy_efficiency_band: "e",
        current_energy_efficiency_rating: 50,
        dwelling_type: "Dwelling-Type0",
        estimated_energy_cost: "689.83",
        main_fuel_type: "36",
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
        property_age_band: "1750",
        property_summary: [
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "walls",
            description: "Brick walls",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "walls",
            description: "Brick walls",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "roof",
            description: "Slate roof",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "roof",
            description: "slate roof",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "floor",
            description: "Tiled floor",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "floor",
            description: "Tiled floor",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "windows",
            description: "Glass window",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating",
            description: "Gas boiler",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating",
            description: "Gas boiler",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating_controls",
            description: "Thermostat",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "main_heating_controls",
            description: "Thermostat",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "secondary_heating",
            description: "Electric heater",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "hot_water",
            description: "Gas boiler",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "lighting",
            description: "Energy saving bulbs",
          },
          {
            energy_efficiency_rating: 0,
            environmental_efficiency_rating: 0,
            name: "air_tightness",
            description: "Draft Exclusion",
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
            indicative_cost: "5",
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
        related_party_disclosure_number: 1,
        related_party_disclosure_text: nil,
        tenure: "1",
        total_floor_area: 10.0,
        status: "ENTERED",
        environmental_impact_current: "50",
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  context "when calling to_report" do
    let(:schemas) do
      [
        {
          schema: "SAP-Schema-18.0.0",
          different_fields: {
            building_reference_number: "UPRN-000000000000",
          },
        },
        {
          schema: "SAP-Schema-17.1",
        },
        {
          schema: "SAP-Schema-17.0",
        },
      ]
    end

    let(:assertion) do
      {
        rrn: "0000-0000-0000-0000-0000",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        building_reference_number: "LPRN-0000000000",
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
        report_type: "1",
        mainheatcont_description: "Thermostat, Thermostat",
        roof_description: "Slate roof, slate roof",
        roof_energy_eff: "N/A, N/A",
        roof_env_eff: "N/A, N/A",
        walls_description: "Brick walls, Brick walls",
        walls_energy_eff: "N/A, N/A",
        walls_env_eff: "N/A, N/A",
        energy_tariff: "standard tariff",


      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion, :to_report)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::SapWrapper.new "", "invalid"
    }.to raise_error(ArgumentError).with_message "Unsupported schema type"
  end
end
