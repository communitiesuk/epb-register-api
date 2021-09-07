describe UseCase::LodgeAssessment do
  subject(:use_case) do
    described_class.new(
      assessments_gateway: assessments_gateway,
      assessments_search_gateway: instance_double(Gateway::AssessmentsSearchGateway),
      address_base_search_gateway: instance_spy(Gateway::AddressBaseSearchGateway),
      assessors_gateway: assessors_gateway,
      assessments_xml_gateway: assessments_xml_gateway,
      assessments_address_id_gateway: instance_spy(Gateway::AssessmentsAddressIdGateway),
      related_assessments_gateway: instance_double(Gateway::RelatedAssessmentsGateway),
      green_deal_plans_gateway: instance_double(Gateway::GreenDealPlansGateway),
      event_broadcaster: EventBroadcaster.new,
    )
  end

  let(:assessments_gateway) { instance_spy(Gateway::AssessmentsGateway) }
  let(:assessors_gateway) { instance_spy(Gateway::AssessorsGateway) }
  let(:assessments_xml_gateway) { instance_spy(Gateway::AssessmentsXmlGateway) }
  let(:assessor) { instance_double(Domain::Assessor) }

  let(:data) do
    { type_of_assessment: "SAP",
      assessment_id: "2000-0000-0000-0000-0001",
      date_of_expiry: "2030-05-03",
      date_of_assessment: "2020-05-04",
      date_of_registration: "2020-05-04",
      date_registered: "2020-05-04",
      address_id: "UPRN-000000000000",
      address_line1: "1 Some Street",
      address_line2: "Some Area",
      address_line3: "Some County",
      address_line4: nil,
      town: "Whitbury",
      postcode: "A0 0AA",
      address: { address_id: "UPRN-000000000000",
                 address_line1: "1 Some Street",
                 address_line2: "Some Area",
                 address_line3: "Some County",
                 address_line4: nil,
                 town: "Whitbury",
                 postcode: "A0 0AA" },
      assessor: { scheme_assessor_id: "SPEC000000",
                  name: "Mr Test Boi TST",
                  contact_details: { email: "a@b.c", telephone: "111222333" } },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "e",
      current_energy_efficiency_rating: 50,
      dwelling_type: "Mid-terrace house",
      estimated_energy_cost: "689.83",
      main_fuel_type: "36",
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
      property_age_band: "1750",
      property_summary: [{ energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "walls",
                           description: "Brick walls" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "walls",
                           description: "Brick walls" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "roof",
                           description: "Slate roof" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "roof",
                           description: "slate roof" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Tiled floor" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "floor",
                           description: "Tiled floor" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "windows",
                           description: "Glass window" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "main_heating",
                           description: "Gas boiler" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "main_heating",
                           description: "Gas boiler" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "main_heating_controls",
                           description: "Thermostat" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "main_heating_controls",
                           description: "Thermostat" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "secondary_heating",
                           description: "Electric heater" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "hot_water",
                           description: "Gas boiler" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "lighting",
                           description: "Energy saving bulbs" },
                         { energy_efficiency_rating: 0,
                           environmental_efficiency_rating: 0,
                           name: "air_tightness",
                           description: "Draft Exclusion" }],
      recommended_improvements: [{ energy_performance_rating_improvement: 50,
                                   environmental_impact_rating_improvement: 50,
                                   green_deal_category_code: "1",
                                   improvement_category: "6",
                                   improvement_code: "5",
                                   improvement_description: nil,
                                   improvement_title: "",
                                   improvement_type: "A",
                                   indicative_cost: "£100 - £350",
                                   sequence: 1,
                                   typical_saving: "360",
                                   energy_performance_band_improvement: "e" },
                                 { energy_performance_rating_improvement: 60,
                                   environmental_impact_rating_improvement: 64,
                                   green_deal_category_code: "3",
                                   improvement_category: "2",
                                   improvement_code: nil,
                                   improvement_description: "Improvement desc",
                                   improvement_title: "",
                                   improvement_type: "Z2",
                                   indicative_cost: "2000",
                                   sequence: 2,
                                   typical_saving: "99",
                                   energy_performance_band_improvement: "d" }],
      lzc_energy_sources: nil,
      related_party_disclosure_number: 1,
      related_party_disclosure_text: nil,
      tenure: "1",
      transaction_type: "1",
      total_floor_area: 98.0,
      status: "ENTERED",
      environmental_impact_current: "52",
      environmental_impact_potential: "74",
      co2_emissions_current_per_floor_area: "20",
      mains_gas: nil,
      level: "1",
      top_storey: "N",
      storey_count: nil,
      main_heating_controls: "Thermostat",
      multiple_glazed_proportion: "50",
      glazed_area: nil,
      habitable_room_count: nil,
      heated_room_count: nil,
      low_energy_lighting: "100",
      fixed_lighting_outlets_count: "8",
      low_energy_fixed_lighting_outlets_count: "8",
      open_fireplaces_count: "0",
      hot_water_description: "Gas boiler",
      hot_water_energy_efficiency_rating: "0",
      hot_water_environmental_efficiency_rating: "0",
      window_description: "Glass window",
      window_energy_efficiency_rating: "0",
      window_environmental_efficiency_rating: "0",
      secondary_heating_description: "Electric heater",
      secondary_heating_energy_efficiency_rating: "0",
      secondary_heating_environmental_efficiency_rating: "0",
      lighting_description: "Energy saving bulbs",
      lighting_energy_efficiency_rating: "0",
      lighting_environmental_efficiency_rating: "0",
      photovoltaic_roof_area_percent: nil,
      heat_loss_corridor: nil,
      wind_turbine_count: "0",
      unheated_corridor_length: nil,
      built_form: "Detached",
      mainheat_description: "Gas boiler, Gas boiler",
      extensions_count: nil,
      addendum: { stone_walls: true },
      raw_data: "<SomeNode></SomeNode>" }
  end

  before do
    allow(assessors_gateway).to receive(:fetch).with("SPEC000000").and_return(assessor)

    allow(assessor).to receive(:domestic_rd_sap_qualification).and_return("ACTIVE")
    allow(assessor).to receive(:scheme_assessor_id).and_return("SPEC000000")
  end

  describe ".execute" do
    it "calls AssessmentsGateway to save the assessment data to the assessments table" do
      use_case.execute(data, true, "RdSAP-Schema-20.0.0")

      expect(assessments_gateway).to have_received(:insert_or_update)
    end

    it "calls AssessmentsXMLGateway to save the XML data to the assessments_xml table" do
      use_case.execute(data, true, "RdSAP-Schema-20.0.0")

      expect(assessments_xml_gateway).to have_received(:send_to_db).with(
        {
          assessment_id: "2000-0000-0000-0000-0001",
          xml: "<SomeNode></SomeNode>",
          schema_type: "RdSAP-Schema-20.0.0",
        },
      )
    end

    context "when event broadcaster is enabled" do
      around do |test|
        EventBroadcaster.enable!
        test.run
        EventBroadcaster.disable!
      end

      it "broadcasts the assessment lodged event" do
        expect { use_case.execute(data, true, "RdSAP-Schema-20.0.0") }.to broadcast(:assessment_lodged)
      end
    end
  end
end
