class SummaryStub
  def self.fetch_summary_rdsap(scheme_id)
    { type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2030-05-03",
      date_of_assessment: "2020-05-04",
      date_of_registration: "2020-05-04",
      date_registered: "2020-05-04",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      town: "Whitbury",
      postcode: "SW1A 2AA",
      address: { address_id: nil, # Set at lodgement, which this unit test doesn't exercise
                 address_line1: "1 Some Street",
                 address_line2: "",
                 address_line3: "",
                 address_line4: "",
                 town: "Whitbury",
                 postcode: "SW1A 2AA" },
      assessor: { first_name: "Someone",
                  last_name: "Person",
                  registered_by: { name: "test scheme", scheme_id: },
                  scheme_assessor_id: "SPEC000000",
                  contact_details: { email: "a@b.c", telephone_number: "0555 497 2848" },
                  search_results_comparison_postcode: "",
                  address: {},
                  company_details: {},
                  qualifications: { domestic_sap: "ACTIVE",
                                    domestic_rd_sap: "ACTIVE",
                                    non_domestic_sp3: "ACTIVE",
                                    non_domestic_cc4: "ACTIVE",
                                    non_domestic_dec: "ACTIVE",
                                    non_domestic_nos3: "ACTIVE",
                                    non_domestic_nos4: "ACTIVE",
                                    non_domestic_nos5: "ACTIVE",
                                    gda: "ACTIVE" },
                  middle_names: "Muddle",
                  date_of_birth: "1991-02-25" },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "e",
      current_energy_efficiency_rating: 50,
      dwelling_type: "Mid-terrace house",
      estimated_energy_cost: "689.83",
      main_fuel_type: "26",
      heat_demand: { current_space_heating_demand: 13_120,
                     current_water_heating_demand: 2285,
                     impact_of_cavity_insulation: -122,
                     impact_of_loft_insulation: -2114,
                     impact_of_solid_wall_insulation: -3560 },
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      potential_carbon_emission: 1.4,
      potential_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 72,
      potential_energy_saving: "174.83",
      primary_energy_use: "230",
      energy_consumption_potential: "88",
      property_age_band: "K",
      property_summary: [{ energy_efficiency_rating: 1,
                           environmental_efficiency_rating: 1,
                           name: "wall",
                           description: "Solid brick, as built, no insulation (assumed)" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "wall",
                           description: "Cavity wall, as built, insulated (assumed)" },
                         { energy_efficiency_rating: 2,
                           environmental_efficiency_rating: 2,
                           name: "roof",
                           description: "Pitched, 25 mm loft insulation" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "roof",
                           description: "Pitched, 250 mm loft insulation" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Suspended, no insulation (assumed)" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Solid, insulated (assumed)" },
                         { energy_efficiency_rating: 3,
                           environmental_efficiency_rating: 3,
                           name: "window",
                           description: "Fully double glazed" },
                         { energy_efficiency_rating: 3,
                           environmental_efficiency_rating: 1,
                           name: "main_heating",
                           description: "Boiler and radiators, anthracite" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "main_heating",
                           description: "Boiler and radiators, mains gas" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "main_heating_controls",
                           description: "Programmer, room thermostat and TRVs" },
                         { energy_efficiency_rating: 5,
                           environmental_efficiency_rating: 5,
                           name: "main_heating_controls",
                           description: "Time and temperature zone control" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "hot_water",
                           description: "From main system" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "lighting",
                           description: "Low energy lighting in 50% of fixed outlets" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "secondary_heating",
                           description: "Room heaters, electric" }],
      recommended_improvements: [{ energy_performance_rating_improvement: 50,
                                   environmental_impact_rating_improvement: 50,
                                   green_deal_category_code: "1",
                                   improvement_category: "6",
                                   improvement_code: "5",
                                   improvement_description: nil,
                                   improvement_title: "",
                                   improvement_type: "Z3",
                                   indicative_cost: "£100 - £350",
                                   sequence: 1,
                                   typical_saving: "360",
                                   energy_performance_band_improvement: "e" },
                                 { energy_performance_rating_improvement: 60,
                                   environmental_impact_rating_improvement: 64,
                                   green_deal_category_code: "3",
                                   improvement_category: "2",
                                   improvement_code: "1",
                                   improvement_description: nil,
                                   improvement_title: "",
                                   improvement_type: "Z2",
                                   indicative_cost: "2000",
                                   sequence: 2,
                                   typical_saving: "99",
                                   energy_performance_band_improvement: "d" },
                                 { energy_performance_rating_improvement: 60,
                                   environmental_impact_rating_improvement: 64,
                                   green_deal_category_code: "3",
                                   improvement_category: "2",
                                   improvement_code: nil,
                                   improvement_description: "Improvement desc",
                                   improvement_title: "",
                                   improvement_type: "Z2",
                                   indicative_cost: "1000",
                                   sequence: 3,
                                   typical_saving: "99",
                                   energy_performance_band_improvement: "d" }],
      lzc_energy_sources: nil,
      related_party_disclosure_number: nil,
      related_party_disclosure_text: "No related party",
      tenure: "1",
      transaction_type: "1",
      total_floor_area: 55.0,
      status: "ENTERED",
      country_code: "EAW",
      environmental_impact_current: 52,
      environmental_impact_potential: 74,
      addendum: { addendum_number: [1, 8], stone_walls: true, system_build: true },
      address_id: nil,  # Set at lodgement, which this unit test doesn't exercise
      opt_out: nil,
      related_assessments: [],
      green_deal_plan: [],
      superseded_by: nil,
      gas_smart_meter_present: nil,
      electricity_smart_meter_present: nil }
  end

  def self.fetch_summary_sap_19(scheme_id)
    { type_of_assessment: "SAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2032-05-08",
      date_of_assessment: "2022-05-09",
      date_of_registration: "2022-05-09",
      date_registered: "2022-05-09",
      address_id: nil,  # Set at lodgement, which this unit test doesn't exercise
      address_line1: "1 Some Street",
      address_line2: "Some Area",
      address_line3: "Some County",
      address_line4: nil,
      town: "Whitbury",
      postcode: "SW1A 2AA",
      address:
         { address_id: nil, # Set at lodgement, which this unit test doesn't exercise
           address_line1: "1 Some Street",
           address_line2: "Some Area",
           address_line3: "Some County",
           address_line4: nil,
           town: "Whitbury",
           postcode: "SW1A 2AA" },
      assessor:
       { first_name: "Someone",
         last_name: "Person",
         registered_by: { name: "test scheme", scheme_id: },
         scheme_assessor_id: "SPEC000000",
         contact_details: { email: "a@b.c", telephone_number: "111222333" },
         search_results_comparison_postcode: "",
         address: {},
         company_details: {},
         qualifications:
          { domestic_sap: "ACTIVE",
            domestic_rd_sap: "ACTIVE",
            non_domestic_sp3: "ACTIVE",
            non_domestic_cc4: "ACTIVE",
            non_domestic_dec: "ACTIVE",
            non_domestic_nos3: "ACTIVE",
            non_domestic_nos4: "ACTIVE",
            non_domestic_nos5: "ACTIVE",
            gda: "ACTIVE" },
         middle_names: "Muddle",
         date_of_birth: "1991-02-25" },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "c",
      current_energy_efficiency_rating: 72,
      dwelling_type: "Mid-terrace house",
      estimated_energy_cost: "689.83",
      main_fuel_type: "39",
      heat_demand:
         { current_space_heating_demand: 13_120,
           current_water_heating_demand: 2285,
           impact_of_cavity_insulation: nil,
           impact_of_loft_insulation: nil,
           impact_of_solid_wall_insulation: nil },
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      potential_carbon_emission: 1.4,
      potential_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 72,
      potential_energy_saving: "174.83",
      primary_energy_use: "59",
      energy_consumption_potential: "53",
      property_age_band: "1750",
      property_summary:
       [{ energy_efficiency_rating: 5,
          environmental_efficiency_rating: 5,
          name: "walls",
          description: "Average thermal transmittance 0.18 W/m²K" },
        { energy_efficiency_rating: 5,
          environmental_efficiency_rating: 5,
          name: "roof",
          description: "Average thermal transmittance 0.13 W/m²K" },
        { energy_efficiency_rating: 5,
          environmental_efficiency_rating: 5,
          name: "floor",
          description: "Average thermal transmittance 0.12 W/m²K" },
        { energy_efficiency_rating: 0,
          environmental_efficiency_rating: 5,
          name: "windows",
          description: "High performance glazing" },
        { energy_efficiency_rating: 3,
          environmental_efficiency_rating: 2,
          name: "main_heating",
          description: "Boiler and radiators, electric" },
        { energy_efficiency_rating: 4,
          environmental_efficiency_rating: 4,
          name: "main_heating_controls",
          description: "Programmer, room thermostat and TRVs" },
        { energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "secondary_heating",
          description: "Electric heater" },
        { energy_efficiency_rating: 4,
          environmental_efficiency_rating: 3,
          name: "hot_water",
          description: "From main system, waste water heat recovery" },
        { energy_efficiency_rating: 5,
          environmental_efficiency_rating: 5,
          name: "lighting",
          description: "Low energy lighting in 91% of fixed outlets" },
        { energy_efficiency_rating: 5,
          environmental_efficiency_rating: 5,
          name: "air_tightness",
          description: "Air permeability 2.0 m³/h.m² (assumed)" }],
      recommended_improvements:
       [{ energy_performance_rating_improvement: 74,
          environmental_impact_rating_improvement: 94,
          green_deal_category_code: "NI",
          improvement_category: "5",
          improvement_code: "19",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "N",
          indicative_cost: "£4,000 - £6,000",
          sequence: 1,
          typical_saving: "88",
          energy_performance_band_improvement: "c" },
        { energy_performance_rating_improvement: 80,
          environmental_impact_rating_improvement: 96,
          green_deal_category_code: "NI",
          improvement_category: "5",
          improvement_code: "34",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "U",
          indicative_cost: "£9,000 - £14,000",
          sequence: 2,
          typical_saving: "88",
          energy_performance_band_improvement: "c" }],
      lzc_energy_sources: nil,
      related_party_disclosure_number: 1,
      related_party_disclosure_text: nil,
      tenure: "1",
      transaction_type: "1",
      total_floor_area: 165.0,
      total_roof_area: 57,
      status: "ENTERED",
      environmental_impact_current: 94,
      environmental_impact_potential: 96,
      co2_emissions_current_per_floor_area: "5.6",
      mains_gas: nil,
      level: nil,
      top_storey: "N",
      storey_count: nil,
      main_heating_controls: "Programmer, room thermostat and TRVs",
      multiple_glazed_proportion: "100",
      glazed_area: nil,
      habitable_room_count: nil,
      heated_room_count: nil,
      low_energy_lighting: 91,
      fixed_lighting_outlets_count: 11,
      low_energy_fixed_lighting_outlets_count: 10,
      open_fireplaces_count: 0,
      hot_water_description: "From main system, waste water heat recovery",
      hot_water_energy_efficiency_rating: "4",
      hot_water_environmental_efficiency_rating: "3",
      window_description: "High performance glazing",
      window_energy_efficiency_rating: "0",
      window_environmental_efficiency_rating: "5",
      secondary_heating_description: "Electric heater",
      secondary_heating_energy_efficiency_rating: "0",
      secondary_heating_environmental_efficiency_rating: "0",
      lighting_description: "Low energy lighting in 91% of fixed outlets",
      lighting_energy_efficiency_rating: "5",
      lighting_environmental_efficiency_rating: "5",
      photovoltaic_roof_area_percent: nil,
      heat_loss_corridor: nil,
      wind_turbine_count: 0,
      unheated_corridor_length: nil,
      built_form: "Mid-Terrace",
      mainheat_description: "Boiler and radiators, electric",
      extensions_count: nil,
      addendum: { stone_walls: true },
      opt_out: nil,
      superseded_by: nil,
      related_assessments: [],
      gas_smart_meter_present: true,
      electricity_smart_meter_present: false,
      country_code: "ENG" }
  end

  def self.fetch_certificate_summary_rdsap(scheme_id)
    { type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2030-05-03",
      date_of_assessment: "2020-05-04",
      date_of_registration: "2020-05-04",
      address: { address_line1: "1 Some Street",
                 address_line2: "",
                 address_line3: "",
                 address_line4: nil,
                 town: "Whitbury",
                 postcode: "SW1A 2AA" },
      assessor: { first_name: "Someone",
                  last_name: "Person",
                  registered_by: { name: "test scheme", scheme_id: },
                  scheme_assessor_id: "SPEC000000",
                  contact_details: { email: "a@b.c", telephone_number: "0555 497 2848" } },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "e",
      current_energy_efficiency_rating: 50,
      dwelling_type: "Mid-terrace house",
      estimated_energy_cost: "689.83",
      heat_demand: { current_space_heating_demand: 13_120,
                     current_water_heating_demand: 2285 },
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      potential_carbon_emission: 1.4,
      potential_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 72,
      potential_energy_saving: "174.83",
      property_summary: [{ energy_efficiency_rating: 1,
                           environmental_efficiency_rating: 1,
                           name: "wall",
                           description: "Solid brick, as built, no insulation (assumed)" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "wall",
                           description: "Cavity wall, as built, insulated (assumed)" },
                         { energy_efficiency_rating: 2,
                           environmental_efficiency_rating: 2,
                           name: "roof",
                           description: "Pitched, 25 mm loft insulation" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "roof",
                           description: "Pitched, 250 mm loft insulation" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Suspended, no insulation (assumed)" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Solid, insulated (assumed)" },
                         { energy_efficiency_rating: 3,
                           environmental_efficiency_rating: 3,
                           name: "window",
                           description: "Fully double glazed" },
                         { energy_efficiency_rating: 3,
                           environmental_efficiency_rating: 1,
                           name: "main_heating",
                           description: "Boiler and radiators, anthracite" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "main_heating",
                           description: "Boiler and radiators, mains gas" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "main_heating_controls",
                           description: "Programmer, room thermostat and TRVs" },
                         { energy_efficiency_rating: 5,
                           environmental_efficiency_rating: 5,
                           name: "main_heating_controls",
                           description: "Time and temperature zone control" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "hot_water",
                           description: "From main system" },
                         { energy_efficiency_rating: 4,
                           environmental_efficiency_rating: 4,
                           name: "lighting",
                           description: "Low energy lighting in 50% of fixed outlets" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "secondary_heating",
                           description: "Room heaters, electric" }],
      recommended_improvements: [{ energy_performance_rating_improvement: 50,
                                   environmental_impact_rating_improvement: 50,
                                   green_deal_category_code: "1",
                                   improvement_category: "6",
                                   improvement_code: "5",
                                   improvement_description: nil,
                                   improvement_title: "",
                                   improvement_type: "Z3",
                                   indicative_cost: "£100 - £350",
                                   sequence: 1,
                                   typical_saving: "360",
                                   energy_performance_band_improvement: "e" },
                                 { energy_performance_rating_improvement: 60,
                                   environmental_impact_rating_improvement: 64,
                                   green_deal_category_code: "3",
                                   improvement_category: "2",
                                   improvement_code: "1",
                                   improvement_description: nil,
                                   improvement_title: "",
                                   improvement_type: "Z2",
                                   indicative_cost: "2000",
                                   sequence: 2,
                                   typical_saving: "99",
                                   energy_performance_band_improvement: "d" },
                                 { energy_performance_rating_improvement: 60,
                                   environmental_impact_rating_improvement: 64,
                                   green_deal_category_code: "3",
                                   improvement_category: "2",
                                   improvement_code: nil,
                                   improvement_description: "Improvement desc",
                                   improvement_title: "",
                                   improvement_type: "Z2",
                                   indicative_cost: "1000",
                                   sequence: 3,
                                   typical_saving: "99",
                                   energy_performance_band_improvement: "d" }],
      lzc_energy_sources: nil,
      related_party_disclosure_number: nil,
      related_party_disclosure_text: "No related party",
      total_floor_area: 55.0,
      status: "ENTERED",
      co2_emissions_current_per_floor_area: "20",
      country_code: "EAW",
      addendum: { addendum_number: [1, 8], stone_walls: true, system_build: true },
      address_id: nil, # Set at lodgement, which this unit test doesn't exercise
      opt_out: nil,
      related_assessments: [],
      green_deal_plan: [],
      superseded_by: nil,
      gas_smart_meter_present: nil,
      electricity_smart_meter_present: nil }
  end

  def self.fetch_certificate_summary_sap_19(scheme_id)
    { type_of_assessment: "SAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2032-05-08",
      date_of_assessment: "2022-05-09",
      date_of_registration: "2022-05-09",
      address_id: nil,
      address:
        { address_line1: "1 Some Street",
          address_line2: "Some Area",
          address_line3: "Some County",
          address_line4: nil,
          town: "Whitbury",
          postcode: "SW1A 2AA" },
      assessor:
        { first_name: "Someone",
          last_name: "Person",
          registered_by: { name: "test scheme", scheme_id: },
          scheme_assessor_id: "SPEC000000",
          contact_details: { email: "a@b.c", telephone_number: "111222333" } },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "c",
      current_energy_efficiency_rating: 72,
      dwelling_type: "Mid-terrace house",
      estimated_energy_cost: "689.83",
      heat_demand:
        { current_space_heating_demand: 13_120,
          current_water_heating_demand: 2285 },
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      potential_carbon_emission: 1.4,
      potential_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 72,
      potential_energy_saving: "174.83",
      property_summary:
        [{ energy_efficiency_rating: 5,
           environmental_efficiency_rating: 5,
           name: "walls",
           description: "Average thermal transmittance 0.18 W/m²K" },
         { energy_efficiency_rating: 5,
           environmental_efficiency_rating: 5,
           name: "roof",
           description: "Average thermal transmittance 0.13 W/m²K" },
         { energy_efficiency_rating: 5,
           environmental_efficiency_rating: 5,
           name: "floor",
           description: "Average thermal transmittance 0.12 W/m²K" },
         { energy_efficiency_rating: 0,
           environmental_efficiency_rating: 5,
           name: "windows",
           description: "High performance glazing" },
         { energy_efficiency_rating: 3,
           environmental_efficiency_rating: 2,
           name: "main_heating",
           description: "Boiler and radiators, electric" },
         { energy_efficiency_rating: 4,
           environmental_efficiency_rating: 4,
           name: "main_heating_controls",
           description: "Programmer, room thermostat and TRVs" },
         { energy_efficiency_rating: 0,
           environmental_efficiency_rating: 0,
           name: "secondary_heating",
           description: "Electric heater" },
         { energy_efficiency_rating: 4,
           environmental_efficiency_rating: 3,
           name: "hot_water",
           description: "From main system, waste water heat recovery" },
         { energy_efficiency_rating: 5,
           environmental_efficiency_rating: 5,
           name: "lighting",
           description: "Low energy lighting in 91% of fixed outlets" },
         { energy_efficiency_rating: 5,
           environmental_efficiency_rating: 5,
           name: "air_tightness",
           description: "Air permeability 2.0 m³/h.m² (assumed)" }],
      recommended_improvements:
        [{ energy_performance_rating_improvement: 74,
           environmental_impact_rating_improvement: 94,
           green_deal_category_code: "NI",
           improvement_category: "5",
           improvement_code: "19",
           improvement_description: nil,
           improvement_title: "",
           improvement_type: "N",
           indicative_cost: "£4,000 - £6,000",
           sequence: 1,
           typical_saving: "88",
           energy_performance_band_improvement: "c" },
         { energy_performance_rating_improvement: 80,
           environmental_impact_rating_improvement: 96,
           green_deal_category_code: "NI",
           improvement_category: "5",
           improvement_code: "34",
           improvement_description: nil,
           improvement_title: "",
           improvement_type: "U",
           indicative_cost: "£9,000 - £14,000",
           sequence: 2,
           typical_saving: "88",
           energy_performance_band_improvement: "c" }],
      lzc_energy_sources: nil,
      related_party_disclosure_number: 1,
      related_party_disclosure_text: nil,
      total_floor_area: 165.0,
      status: "ENTERED",
      co2_emissions_current_per_floor_area: "5.6",
      addendum: { stone_walls: true },
      opt_out: nil,
      superseded_by: nil,
      related_assessments: [],
      gas_smart_meter_present: true,
      electricity_smart_meter_present: false,
      country_code: "ENG" }
  end
end
